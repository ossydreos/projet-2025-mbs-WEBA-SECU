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
        print('🔍 NotificationService: Vérification de l\'offre $customOfferId...');
        final offerDoc = await _firestore.collection('custom_offers').doc(customOfferId).get();
        if (!offerDoc.exists) {
          print('❌ NotificationService: Offre $customOfferId non trouvée');
          throw Exception('Offre non trouvée');
        }
        
        final offerData = offerDoc.data()!;
        final currentStatus = offerData['status'] as String?;
        print('🔍 NotificationService: Statut actuel de l\'offre $customOfferId: $currentStatus');
        
        if (currentStatus != ReservationStatus.confirmed.name) {
          print('❌ NotificationService: Offre $customOfferId n\'est plus confirmée (statut: $currentStatus)');
          throw Exception('Cette offre a déjà été traitée ou annulée');
        }
        print('✅ NotificationService: Offre $customOfferId validée, procédure au paiement');
      } else {
        // Vérifier le statut actuel de la réservation avant de confirmer le paiement
        final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
        if (!reservationDoc.exists) {
          print('❌ NotificationService: Réservation $reservationId non trouvée');
          throw Exception('Réservation non trouvée');
        }

        final reservationData = reservationDoc.data()!;
        final currentStatus = reservationData['status'] as String?;

        // Vérifier que la réservation est toujours confirmée (en attente de paiement)
        if (currentStatus != ReservationStatus.confirmed.name) {
          print('❌ NotificationService: Réservation $reservationId n\'est plus confirmée (statut: $currentStatus)');
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
      
      print('✅ NotificationService: Paiement en espèces confirmé pour la réservation $reservationId');
    } catch (e) {
      print('❌ NotificationService: Erreur lors de la confirmation du paiement: $e');
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
