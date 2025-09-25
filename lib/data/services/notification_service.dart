import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../../widgets/admin/uber_style_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Confirmer le paiement et passer en "confirmed"
  Future<void> confirmPayment(String reservationId) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': ReservationStatus
            .inProgress
            .name, // ✅ CORRECTION : Passer en inProgress après paiement
        'lastUpdated': Timestamp.now(),
        'paymentConfirmedAt': Timestamp.now(),
      });

      // Mettre à jour l'offre personnalisée liée (si existe) pour refléter le paiement
      final offers = await _firestore
          .collection('custom_offers')
          .where('reservationId', isEqualTo: reservationId)
          .limit(1)
          .get();
      if (offers.docs.isNotEmpty) {
        await offers.docs.first.reference.update({
          'status': 'confirmed',
          'paymentMethod': 'cash',
          'confirmedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement: $e');
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Afficher une notification style Uber pour les nouvelles demandes
  static void showUberStyleNotification(
    BuildContext context,
    Reservation reservation, {
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    VoidCallback? onCounterOffer,
    VoidCallback? onPending,
  }) {
    // Fermer toute notification existante
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Afficher la notification plein écran
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: UberStyleNotification(
            reservation: reservation,
            onAccept: () {
              Navigator.of(context).pop();
              onAccept();
            },
            onDecline: () {
              Navigator.of(context).pop();
              onDecline();
            },
            onClose: () {
              Navigator.of(context).pop();
              onDecline(); // Fermer = refuser par défaut
            },
            onCounterOffer: onCounterOffer != null
                ? () {
                    Navigator.of(context).pop();
                    onCounterOffer();
                  }
                : null,
            onPending: onPending != null
                ? () {
                    Navigator.of(context).pop();
                    onPending();
                  }
                : null,
          ),
        );
      },
    );
  }
}
