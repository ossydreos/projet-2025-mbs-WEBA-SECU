import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_chat_thread.dart';
import '../models/support_message.dart';

/// Service de chat lié à une réservation (client <-> admin)
class RideChatService {
  static const String threadsCollection = 'ride_chat_threads';
  static const String messagesSubcollection = 'messages';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Ouvre (ou crée) le thread pour une réservation donnée et un utilisateur
  Future<RideChatThread> openOrCreateThread({
    required String reservationId,
    String? userId,
  }) async {
    final uid = userId ?? currentUserId;
    if (uid == null) {
      throw Exception('Utilisateur non connecté');
    }

    final existing = await _firestore
        .collection(threadsCollection)
        .where('reservationId', isEqualTo: reservationId)
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final d = existing.docs.first;
      return RideChatThread.fromMap(d.data(), d.id);
    }

    final ref = _firestore.collection(threadsCollection).doc();
    final now = DateTime.now();
    final thread = RideChatThread(
      id: ref.id,
      reservationId: reservationId,
      userId: uid,
      createdAt: now,
      updatedAt: now,
      unreadForUser: 0,
      unreadForAdmin: 0,
      isClosed: false,
    );
    await ref.set(thread.toMap());
    return thread;
  }

  /// Récupère le thread par id
  Stream<RideChatThread?> watchThreadById(String threadId) {
    return _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .snapshots()
        .map((d) => d.exists ? RideChatThread.fromMap(d.data()!, d.id) : null);
  }

  /// Récupère le thread d'une réservation pour un utilisateur
  Future<RideChatThread?> getThreadByReservation({
    required String reservationId,
    required String userId,
  }) async {
    final q = await _firestore
        .collection(threadsCollection)
        .where('reservationId', isEqualTo: reservationId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return RideChatThread.fromMap(d.data(), d.id);
  }

  /// Messages d'un thread (sous-collection)
  Stream<List<SupportMessage>> watchMessages(String threadId) {
    return _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .collection(messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => SupportMessage.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> setThreadClosed({required String threadId, required bool isClosed}) async {
    final now = DateTime.now();
    await _firestore.collection(threadsCollection).doc(threadId).update({
      'isClosed': isClosed,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Supprime le thread de chat pour une réservation donnée
  Future<void> deleteThreadForReservation(String reservationId) async {
    try {
      // Récupérer tous les threads pour cette réservation
      final threads = await _firestore
          .collection(threadsCollection)
          .where('reservationId', isEqualTo: reservationId)
          .get();

      // Supprimer chaque thread et ses messages
      for (final threadDoc in threads.docs) {
        final threadId = threadDoc.id;
        
        // Supprimer tous les messages du thread
        final messages = await _firestore
            .collection(threadsCollection)
            .doc(threadId)
            .collection(messagesSubcollection)
            .get();
        
        for (final messageDoc in messages.docs) {
          await messageDoc.reference.delete();
        }
        
        // Supprimer le thread
        await threadDoc.reference.delete();
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting ride chat thread',
        name: 'RideChatService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de supprimer le thread');
    }
  }

  /// Envoi d'un message (réutilise SupportMessage)
  Future<void> sendMessage({
    required String threadId,
    required String text,
    required SupportSenderRole senderRole,
  }) async {
    final uid = currentUserId ?? 'admin';
    final now = DateTime.now();

    final msgRef = _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .collection(messagesSubcollection)
        .doc();
    final msg = SupportMessage(
      id: msgRef.id,
      threadId: threadId,
      senderId: uid,
      senderRole: senderRole,
      text: text.trim(),
      createdAt: now,
      readByUser: senderRole == SupportSenderRole.user,
      readByAdmin: senderRole == SupportSenderRole.admin,
    );

    final threadRef = _firestore.collection(threadsCollection).doc(threadId);
    await _firestore.runTransaction((tx) async {
      final threadSnap = await tx.get(threadRef);
      final current = threadSnap.data() as Map<String, dynamic>?;
      final unreadForUser = (current?['unreadForUser'] ?? 0) as int;
      final unreadForAdmin = (current?['unreadForAdmin'] ?? 0) as int;

      tx.set(msgRef, msg.toMap());
      tx.update(threadRef, {
        'lastMessage': msg.text,
        'lastMessageAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadForUser': senderRole == SupportSenderRole.admin
            ? unreadForUser + 1
            : unreadForUser,
        'unreadForAdmin': senderRole == SupportSenderRole.user
            ? unreadForAdmin + 1
            : unreadForAdmin,
      });
    });
  }

  Future<void> markAsReadForUser(String threadId) async {
    await _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .update({'unreadForUser': 0});
  }

  Future<void> markAsReadForAdmin(String threadId) async {
    await _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .update({'unreadForAdmin': 0});
  }

  Future<void> markMessagesAsReadForAdmin(String threadId) async {
    final q = await _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .collection(messagesSubcollection)
        .where('senderRole', isEqualTo: SupportSenderRole.user.name)
        .where('readByAdmin', isEqualTo: false)
        .get();
    if (q.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'readByAdmin': true});
    }
    await batch.commit();
  }

  Future<void> markMessagesAsReadForUser(String threadId) async {
    final q = await _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .collection(messagesSubcollection)
        .where('senderRole', isEqualTo: SupportSenderRole.admin.name)
        .where('readByUser', isEqualTo: false)
        .get();
    if (q.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'readByUser': true});
    }
    await batch.commit();
  }
}


