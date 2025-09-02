import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection Firestore
  static const String _collection = 'reservations';

  // Créer une nouvelle réservation
  Future<String> createReservation(Reservation reservation) async {
    try {
      // Générer un ID unique
      final docRef = _firestore.collection(_collection).doc();
      final reservationWithId = reservation.copyWith(id: docRef.id);

      // Sauvegarder dans Firestore
      await docRef.set(reservationWithId.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }

  // Obtenir toutes les réservations d'un utilisateur
  Future<List<Reservation>> getUserReservations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations: $e');
    }
  }

  // Obtenir une réservation par ID
  Future<Reservation?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reservationId).get();
      
      if (doc.exists) {
        return Reservation.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la réservation: $e');
    }
  }

  // Mettre à jour le statut d'une réservation
  Future<void> updateReservationStatus(String reservationId, ReservationStatus newStatus) async {
    try {
      await _firestore.collection(_collection).doc(reservationId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Mettre à jour une réservation complète
  Future<void> updateReservation(Reservation reservation) async {
    try {
      final updatedReservation = reservation.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(reservation.id)
          .update(updatedReservation.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la réservation: $e');
    }
  }

  // Supprimer une réservation
  Future<void> deleteReservation(String reservationId) async {
    try {
      await _firestore.collection(_collection).doc(reservationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la réservation: $e');
    }
  }

  // Obtenir les réservations en attente (pour les conducteurs/admin)
  Future<List<Reservation>> getPendingReservations() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations en attente: $e');
    }
  }

  // Obtenir l'utilisateur actuel
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Vérifier si l'utilisateur est connecté
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Stream des réservations d'un utilisateur (pour les mises à jour en temps réel)
  Stream<List<Reservation>> getUserReservationsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromMap(doc.data()))
            .toList());
  }

  // Stream des réservations en attente (pour les conducteurs)
  Stream<List<Reservation>> getPendingReservationsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromMap(doc.data()))
            .toList());
  }
}
