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
        'isPaid': true, // Marquer comme payé
      });
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
    print('🔔 NotificationService: showUberStyleNotification appelé');
    print('🔔 NotificationService: Contexte monté: ${context.mounted}');
    print('🔔 NotificationService: Réservation: ${reservation.id}');

    // Fermer toute notification existante
    Navigator.of(context).popUntil((route) => route.isFirst);

    print('🔔 NotificationService: Affichage de la notification plein écran');

    // Afficher la notification plein écran
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (BuildContext context) {
        print('🔔 NotificationService: Builder de showDialog appelé');
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
              if (onPending != null) {
                onPending(); // Fermer = mettre en attente
              } else {
                onDecline(); // Fallback si onPending n'est pas fourni
              }
            },
            onCounterOffer: onCounterOffer != null
                ? () {
                    Navigator.of(context).pop();
                    onCounterOffer();
                  }
                : null,
          ),
        );
      },
    );
  }
}
