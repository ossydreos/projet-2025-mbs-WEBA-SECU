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

  // Afficher une notification style barre en bas pour les nouvelles demandes
  static void showUberStyleNotification(
    BuildContext context,
    Reservation reservation, {
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    VoidCallback? onCounterOffer,
    VoidCallback? onPending,
  }) {
    // Afficher la notification comme une barre en bas
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouvelle demande',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${reservation.departure} → ${reservation.destination}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        onAccept();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('ACCEPTER'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        onDecline();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('REFUSER'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.fixed,
        action: SnackBarAction(
          label: 'FERMER',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onDecline();
          },
        ),
      ),
    );
  }
}
