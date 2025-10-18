import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../../widgets/admin/uber_style_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Confirmer le paiement et passer en "inProgress" (paiement en espèces)
  Future<void> confirmPayment(String reservationId, {String? customOfferId}) async {
    try {
      // Si c'est une offre personnalisée, vérifier le statut de l'offre
      if (customOfferId != null) {
        final offerDoc = await _firestore.collection('custom_offers').doc(customOfferId).get();
        if (!offerDoc.exists) {
          throw Exception('Offre non trouvée');
        }
        
        final offerData = offerDoc.data()!;
        final currentStatus = offerData['status'] as String?;
        
        if (currentStatus != ReservationStatus.confirmed.name) {
          throw Exception('Cette offre a déjà été traitée ou annulée');
        }
      } else {
        // Vérifier le statut actuel de la réservation avant de confirmer le paiement
        final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
        if (!reservationDoc.exists) {
          throw Exception('Réservation non trouvée');
        }

        final reservationData = reservationDoc.data()!;
        final currentStatus = reservationData['status'] as String?;

        // Vérifier que la réservation est toujours confirmée (en attente de paiement)
        if (currentStatus != ReservationStatus.confirmed.name) {
          throw Exception('Cette réservation a déjà été traitée ou annulée');
        }
      }
      
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': ReservationStatus
            .inProgress
            .name, // ✅ CORRECTION : Passer en inProgress après paiement
        'lastUpdated': Timestamp.now(),
        'paymentConfirmedAt': Timestamp.now(),
        'isPaid': true, // Marquer comme payé
        'paymentMethod': 'Espèces',
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
    VoidCallback? onClose,
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
              onClose?.call();
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
