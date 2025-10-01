import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation.dart';

/// Service pour migrer les données existantes
class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Migrer les réservations existantes pour ajouter les champs isPaid et isCompleted
  static Future<void> migrateReservations() async {
    try {
      print('🔄 Début de la migration des réservations...');

      // Récupérer toutes les réservations
      final snapshot = await _firestore.collection('reservations').get();

      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Vérifier si les champs existent déjà
        if (data.containsKey('isPaid') && data.containsKey('isCompleted')) {
          continue; // Déjà migré
        }

        // Déterminer les valeurs par défaut
        final status = data['status'] as String?;
        final isPaid = status != null && status != 'pending';
        final isCompleted = status == 'completed';

        // Mettre à jour la réservation
        await _firestore.collection('reservations').doc(doc.id).update({
          'isPaid': isPaid,
          'isCompleted': isCompleted,
          'migratedAt': Timestamp.now(),
        });

        updatedCount++;
        print(
          '✅ Réservation ${doc.id} migrée (isPaid: $isPaid, isCompleted: $isCompleted)',
        );
      }

      print('🎉 Migration terminée ! $updatedCount réservations mises à jour.');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }

  /// Vérifier si la migration est nécessaire
  static Future<bool> needsMigration() async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false; // Aucune réservation à migrer
      }

      final data = snapshot.docs.first.data();
      return !data.containsKey('isPaid') || !data.containsKey('isCompleted');
    } catch (e) {
      print('❌ Erreur lors de la vérification de migration: $e');
      return false;
    }
  }
}
