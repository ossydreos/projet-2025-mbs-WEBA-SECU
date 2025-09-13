import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../../theme/glassmorphism_theme.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pour écouter les changements de statut des réservations
  Stream<List<Reservation>> getReservationUpdatesStream(String userId) {
    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Stream pour écouter les contre-offres
  Stream<List<Map<String, dynamic>>> getCounterOffersStream(String userId) {
    return _firestore
        .collection('counter_offers')
        .where('reservationId', isEqualTo: null) // Sera filtré côté client
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  // Obtenir les contre-offres pour une réservation spécifique
  Future<List<Map<String, dynamic>>> getCounterOffersForReservation(String reservationId) async {
    try {
      final querySnapshot = await _firestore
          .collection('counter_offers')
          .where('reservationId', isEqualTo: reservationId)
          .get();

      // Filtrer côté client pour éviter les problèmes d'index
      final counterOffers = querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((offer) => offer['status'] == 'pending')
          .toList();

      // Trier par date de création (descendant)
      counterOffers.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return counterOffers;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des contre-offres: $e');
    }
  }

  // Accepter une contre-offre
  Future<void> acceptCounterOffer(String counterOfferId, String reservationId) async {
    try {
      final batch = _firestore.batch();

      // 1. Mettre à jour la contre-offre
      final counterOfferRef = _firestore.collection('counter_offers').doc(counterOfferId);
      batch.update(counterOfferRef, {
        'status': 'accepted',
        'acceptedAt': Timestamp.now(),
      });

      // 2. Mettre à jour la réservation
      final reservationRef = _firestore.collection('reservations').doc(reservationId);
      batch.update(reservationRef, {
        'status': 'waiting_payment',
        'lastUpdated': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation de la contre-offre: $e');
    }
  }

  // Rejeter une contre-offre
  Future<void> rejectCounterOffer(String counterOfferId) async {
    try {
      await _firestore.collection('counter_offers').doc(counterOfferId).update({
        'status': 'rejected',
        'rejectedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors du rejet de la contre-offre: $e');
    }
  }

  // Confirmer le paiement et passer en "confirmed"
  Future<void> confirmPayment(String reservationId) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': 'inProgress', // ✅ CORRECTION : Passer en inProgress après paiement
        'lastUpdated': Timestamp.now(),
        'paymentConfirmedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement: $e');
    }
  }

  // Afficher une notification de contre-offre
  static void showCounterOfferNotification(BuildContext context, Map<String, dynamic> counterOffer) {
    final proposedDate = (counterOffer['proposedDate'] as Timestamp).toDate();
    final proposedTime = counterOffer['proposedTime'] as String;
    final message = counterOffer['adminMessage'] as String? ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Nouvelle contre-offre reçue !',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Date proposée: ${proposedDate.day}/${proposedDate.month} à $proposedTime'),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Message: $message'),
            ],
          ],
        ),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Navigation vers l'écran de détail de la réservation
            // TODO: Implémenter la navigation
          },
        ),
      ),
    );
  }

  // Afficher une notification de confirmation
  static void showConfirmationNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Réservation confirmée ! Validez et payez maintenant.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
