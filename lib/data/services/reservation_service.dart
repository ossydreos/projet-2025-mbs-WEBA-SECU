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
      final docRef = _firestore.collection(_collection).doc();
      final reservationWithId = reservation.copyWith(id: docRef.id);
      await docRef.set(reservationWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }



  // Mettre à jour le statut d'une réservation
  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus newStatus,
  ) async {
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
      final updatedReservation = reservation.copyWith(
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(_collection)
          .doc(reservation.id)
          .update(updatedReservation.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la réservation: $e');
    }
  }


  // Obtenir les réservations en attente (pour les conducteurs/admin)
  Future<List<Reservation>> getPendingReservations() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Reservation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des réservations en attente: $e',
      );
    }
  }

  // Obtenir l'utilisateur actuel
  String? getCurrentUserId() => _auth.currentUser?.uid;

  // Vérifier si l'utilisateur est connecté
  bool isUserLoggedIn() => _auth.currentUser != null;

  // ✅ Stream général de toutes les réservations (pour admin)
  Stream<QuerySnapshot> getReservationsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Stream des réservations d'un utilisateur (pour les mises à jour en temps réel)
  Stream<List<Reservation>> getUserReservationsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Stream des réservations confirmées d'un utilisateur (pour l'onglet "À venir")
  Stream<List<Reservation>> getUserConfirmedReservationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'inProgress')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }



  // Stream des réservations terminées d'un utilisateur (pour l'onglet "Terminés")
  Stream<List<Reservation>> getUserCompletedReservationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // ✅ OPTIMISÉ : Méthode générique pour enrichir les réservations avec les noms d'utilisateurs
  Future<Reservation> _enrichReservationWithUserName(
    Reservation reservation,
  ) async {
    if (reservation.userName != null && reservation.userName!.isNotEmpty) {
      return reservation;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(reservation.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        final displayName = userData['displayName'] ?? '';
        final email = userData['email'] ?? '';

        String userName = 'Utilisateur';
        if (displayName.isNotEmpty) {
          userName = displayName;
        } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
          userName = '$firstName $lastName'.trim();
        } else if (email.isNotEmpty) {
          userName = email.split('@')[0];
        }

        return reservation.copyWith(userName: userName);
      }
    } catch (e) {
      // En cas d'erreur, garder le nom par défaut
    }

    return reservation.copyWith(userName: 'Utilisateur');
  }

  // Stream des réservations en attente (pour les conducteurs)
  Stream<List<Reservation>> getPendingReservationsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reservations = <Reservation>[];
          for (var doc in snapshot.docs) {
            var reservation = Reservation.fromMap({
              ...doc.data(),
              'id': doc.id,
            });
            reservation = await _enrichReservationWithUserName(reservation);
            reservations.add(reservation);
          }
          return reservations;
        });
  }

  // ✅ Stream des réservations confirmées (TOUTES - pour admin)
  Stream<List<Reservation>> getConfirmedReservationsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: ReservationStatus.confirmed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reservations = <Reservation>[];
          for (var doc in snapshot.docs) {
            var reservation = Reservation.fromMap({
              ...doc.data(),
              'id': doc.id,
            });
            reservation = await _enrichReservationWithUserName(reservation);
            reservations.add(reservation);
          }
          return reservations;
        });
  }

  // ✅ Stream des réservations en cours (payées)
  Stream<List<Reservation>> getInProgressReservationsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: ReservationStatus.inProgress.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reservations = <Reservation>[];
          for (var doc in snapshot.docs) {
            var reservation = Reservation.fromMap({
              ...doc.data(),
              'id': doc.id,
            });
            reservation = await _enrichReservationWithUserName(reservation);
            reservations.add(reservation);
          }
          return reservations;
        });
  }


  // ✅ Stream des réservations terminées (TOUTES - pour admin)
  Stream<List<Reservation>> getCompletedReservationsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: ReservationStatus.completed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reservations = <Reservation>[];
          for (var doc in snapshot.docs) {
            var reservation = Reservation.fromMap({
              ...doc.data(),
              'id': doc.id,
            });
            reservation = await _enrichReservationWithUserName(reservation);
            reservations.add(reservation);
          }
          return reservations;
        });
  }

  // Stream des réservations en attente pour un utilisateur spécifique
  Stream<List<Reservation>> getUserPendingReservationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

}
