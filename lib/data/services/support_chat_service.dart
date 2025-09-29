import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/support_thread.dart';
import '../models/support_message.dart';

class SupportChatService {
  static const String threadsCollection = 'support_threads';
  static const String messagesCollection = 'support_messages';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Crée (ou récupère) le thread associé à l'utilisateur courant
  Future<SupportThread> openOrCreateThreadForCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('Utilisateur non connecté');
    }

    final existing = await _firestore
        .collection(threadsCollection)
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final d = existing.docs.first;
      return SupportThread.fromMap(d.data(), d.id);
    }

    final ref = _firestore.collection(threadsCollection).doc();
    final now = DateTime.now();
    final thread = SupportThread(
      id: ref.id,
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

  // Récupère les threads pour l'admin (tri par lastMessageAt desc)
  Stream<List<SupportThread>> watchAllThreadsForAdmin() {
    return _firestore
        .collection(threadsCollection)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => SupportThread.fromMap(d.data(), d.id))
            .toList());
  }

  // Observe le thread d'un user (client)
  Stream<SupportThread?> watchThreadForCurrentUser() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection(threadsCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          if (s.docs.isEmpty) return null;
          // Trier côté client par lastMessageAt desc, fallback createdAt
          final threads = s.docs
              .map((d) => SupportThread.fromMap(d.data(), d.id))
              .toList();
          threads.sort((a, b) {
            final da = a.lastMessageAt ?? a.updatedAt;
            final db = b.lastMessageAt ?? b.updatedAt;
            return db.compareTo(da);
          });
          return threads.first;
        });
  }

  // Liste de tous les threads du client (triés côté client)
  Stream<List<SupportThread>> watchThreadsForCurrentUser() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection(threadsCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => SupportThread.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) {
            final da = a.lastMessageAt ?? a.updatedAt;
            final db = b.lastMessageAt ?? b.updatedAt;
            return db.compareTo(da);
          });
          return list;
        });
  }

  // Créer un nouveau thread (toujours) pour le client
  Future<SupportThread> createNewThreadForCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('Utilisateur non connecté');
    }
    final ref = _firestore.collection(threadsCollection).doc();
    final now = DateTime.now();
    final thread = SupportThread(
      id: ref.id,
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

  // Messages d'un thread
  Stream<List<SupportMessage>> watchMessages(String threadId) {
    return _firestore
        .collection(messagesCollection)
        .where('threadId', isEqualTo: threadId)
        .snapshots()
        .map((s) {
          final messages = s.docs
              .map((d) => SupportMessage.fromMap(d.data(), d.id))
              .toList();
          // Trier manuellement par createdAt
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  // Watch un thread par son id
  Stream<SupportThread?> watchThreadById(String threadId) {
    return _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .snapshots()
        .map((d) => d.exists ? SupportThread.fromMap(d.data()!, d.id) : null);
  }

  Future<void> setThreadClosed({required String threadId, required bool isClosed}) async {
    final now = DateTime.now();
    await _firestore.collection(threadsCollection).doc(threadId).update({
      'isClosed': isClosed,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // Envoyer un message
  Future<void> sendMessage({
    required String threadId,
    required String text,
    required SupportSenderRole senderRole,
  }) async {
    final uid = currentUserId ?? 'admin';
    final now = DateTime.now();

    final msgRef = _firestore.collection(messagesCollection).doc();
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
      // LECTURE AVANT ÉCRITURES (contrainte Firestore)
      final threadSnap = await tx.get(threadRef);
      final current = threadSnap.data() as Map<String, dynamic>?;
      final unreadForUser = (current?['unreadForUser'] ?? 0) as int;
      final unreadForAdmin = (current?['unreadForAdmin'] ?? 0) as int;
      final hadMessages = (current?['lastMessageAt'] != null);

      // ÉCRITURES APRÈS TOUTES LES LECTURES
      tx.set(msgRef, msg.toMap());

      if (!hadMessages && senderRole == SupportSenderRole.user) {
        // On ne pousse pas le message auto ici: on le fera 5s plus tard (hors transaction)
        tx.update(threadRef, {
          'lastMessage': msg.text,
          'lastMessageAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'unreadForAdmin': unreadForAdmin + 1,
        });
      } else {
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
      }
    });

    // Message automatique différé (5s) si c'était le premier message d'un ticket client
    if (senderRole == SupportSenderRole.user) {
      print('🔍 Vérification message auto pour thread: $threadId');
      final allMessagesSnap = await _firestore
          .collection(messagesCollection)
          .where('threadId', isEqualTo: threadId)
          .get();
      print('📊 Nombre total de messages dans le thread: ${allMessagesSnap.docs.length}');
      
      final isFirst = allMessagesSnap.docs.length == 1;
      print('🎯 Premier message? $isFirst');
      
      if (isFirst) {
        print('⏰ Démarrage timer 5s pour message auto...');
        Future.delayed(const Duration(seconds: 5), () async {
          print('🚀 Timer écoulé, envoi du message auto...');
          
          // Vérifier si un admin a répondu entre-temps
          final adminMessages = await _firestore
              .collection(messagesCollection)
              .where('threadId', isEqualTo: threadId)
              .where('senderRole', isEqualTo: SupportSenderRole.admin.name)
              .get();
          
          print('👨‍💼 Messages admin trouvés: ${adminMessages.docs.length}');
          
          if (adminMessages.docs.isNotEmpty) {
            print('❌ Admin a déjà répondu, annulation message auto');
            return;
          }

          print('✅ Envoi du message automatique...');
          final autoRef = _firestore.collection(messagesCollection).doc();
          final autoNow = DateTime.now();
          const autoText = 'Merci, votre message a bien été envoyé. Notre équipe vous répond généralement en quelques minutes.\n\n— Message automatique';
          final autoMsg = SupportMessage(
            id: autoRef.id,
            threadId: threadId,
            senderId: 'admin_auto',
            senderRole: SupportSenderRole.admin,
            text: autoText,
            createdAt: autoNow,
            readByUser: false,
            readByAdmin: true,
          );
          
          try {
            await _firestore.runTransaction((tx) async {
              tx.set(autoRef, autoMsg.toMap());
              tx.update(_firestore.collection(threadsCollection).doc(threadId), {
                'lastMessage': autoMsg.text,
                'lastMessageAt': Timestamp.fromDate(autoNow),
                'updatedAt': Timestamp.fromDate(autoNow),
                'unreadForUser': FieldValue.increment(1),
              });
            });
            print('✅ Message automatique envoyé avec succès!');
          } catch (e) {
            print('❌ Erreur envoi message auto: $e');
          }
        });
      }
    }
  }

  // Marquer comme lu pour le client
  Future<void> markAsReadForUser(String threadId) async {
    await _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .update({'unreadForUser': 0});
  }

  // Marquer comme lu pour l'admin
  Future<void> markAsReadForAdmin(String threadId) async {
    await _firestore
        .collection(threadsCollection)
        .doc(threadId)
        .update({'unreadForAdmin': 0});
  }

  // Marquer tous les messages comme lus côté ADMIN (messages envoyés par USER)
  Future<void> markMessagesAsReadForAdmin(String threadId) async {
    final q = await _firestore
        .collection(messagesCollection)
        .where('threadId', isEqualTo: threadId)
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

  // Marquer tous les messages comme lus côté USER (messages envoyés par ADMIN)
  Future<void> markMessagesAsReadForUser(String threadId) async {
    final q = await _firestore
        .collection(messagesCollection)
        .where('threadId', isEqualTo: threadId)
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


