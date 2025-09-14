import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../../theme/glassmorphism_theme.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;




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
