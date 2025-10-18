import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

class ClientNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection pour les notifications
  static const String _collection = 'notifications';

  // Créer une notification pour un client
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String
    type, // 'reservation_refused', 'reservation_cancelled', 'reservation_confirmed', etc.
    String? reservationId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'reservationId': reservationId,
        'data': data ?? {},
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création de la notification: $e');
    }
  }

  // Notifier le client d'un refus de réservation
  Future<void> notifyReservationRefused({
    required String userId,
    required String reservationId,
    String? reason,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Demande de course refusée',
      message: reason != null
          ? 'Votre demande de course a été refusée. Raison: $reason'
          : 'Votre demande de course a été refusée.',
      type: 'reservation_refused',
      reservationId: reservationId,
      data: {'reason': reason},
    );
  }

  // Notifier le client d'une annulation de course confirmée
  Future<void> notifyReservationCancelled({
    required String userId,
    required String reservationId,
    String? reason,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Course annulée',
      message: reason != null
          ? 'Votre course confirmée a été annulée. Raison: $reason'
          : 'Votre course confirmée a été annulée.',
      type: 'reservation_cancelled',
      reservationId: reservationId,
      data: {'reason': reason},
    );
  }

  // Notifier le client d'une confirmation de réservation
  Future<void> notifyReservationConfirmed({
    required String userId,
    required String reservationId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Course confirmée',
      message:
          'Votre demande de course a été confirmée. Un chauffeur sera assigné bientôt.',
      type: 'reservation_confirmed',
      reservationId: reservationId,
    );
  }

  // Notifier le client d'un changement de statut
  Future<void> notifyReservationStatusChanged({
    required String userId,
    required String reservationId,
    required ReservationStatus oldStatus,
    required ReservationStatus newStatus,
    String? reason,
  }) async {
    String title;
    String message;

    switch (newStatus) {
      case ReservationStatus.confirmed:
        title = 'Course confirmée';
        message = 'Votre demande de course a été confirmée.';
        break;
      case ReservationStatus.inProgress:
        title = 'Course en cours';
        message = 'Votre course a commencé. Le chauffeur est en route.';
        break;
      case ReservationStatus.completed:
        title = 'Course terminée';
        message = 'Votre course a été terminée avec succès.';
        break;
      case ReservationStatus.cancelled:
        title = 'Course annulée';
        message = reason != null
            ? 'Votre course a été annulée. Raison: $reason'
            : 'Votre course a été annulée.';
        break;
      case ReservationStatus.pending:
        title = 'Demande en attente';
        message = 'Votre demande de course est en attente de confirmation.';
        break;
    }

    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'reservation_status_changed',
      reservationId: reservationId,
      data: {
        'oldStatus': oldStatus.name,
        'newStatus': newStatus.name,
        'reason': reason,
      },
    );
  }

  // Obtenir les notifications d'un utilisateur
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }
      await batch.commit();
    } catch (e) {
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
    }
  }

  // Supprimer toutes les notifications d'un utilisateur
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final notifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
    }
  }

  // Obtenir le nombre de notifications non lues
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
