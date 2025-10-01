import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation.dart';
import 'client_notification_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ClientNotificationService _notificationService =
      ClientNotificationService();

  // Collection Firestore
  static const String _collection = 'reservations';

  // Cache pour les noms d'utilisateurs
  static final Map<String, String> _userNameCache = <String, String>{};

  // Méthode pour vider le cache (utile lors de la déconnexion)
  static void clearUserNameCache() {
    _userNameCache.clear();
  }

  // Créer une nouvelle réservation
  Future<String> createReservation(Reservation reservation) async {
    try {
      // Validation : empêcher les réservations dans le passé
      _validateReservationDate(reservation.selectedDate, reservation.selectedTime);
      
      final docRef = _firestore.collection(_collection).doc();
      final reservationWithId = reservation.copyWith(id: docRef.id);
      await docRef.set(reservationWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }
  
  // Valider que la date et l'heure de réservation ne sont pas dans le passé
  void _validateReservationDate(DateTime selectedDate, String selectedTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // Vérifier si la date est dans le passé
    if (selectedDateOnly.isBefore(today)) {
      throw Exception('Impossible de réserver pour une date passée');
    }
    
    // Si c'est aujourd'hui, vérifier que l'heure n'est pas dans le passé
    if (selectedDateOnly.isAtSameMomentAs(today)) {
      final timeParts = selectedTime.split(':');
      if (timeParts.length == 2) {
        final selectedHour = int.tryParse(timeParts[0]) ?? 0;
        final selectedMinute = int.tryParse(timeParts[1]) ?? 0;
        
        final selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedHour,
          selectedMinute,
        );
        
        // Ajouter 30 minutes de marge pour la préparation
        final minimumDateTime = now.add(const Duration(minutes: 30));
        
        if (selectedDateTime.isBefore(minimumDateTime)) {
          throw Exception('Impossible de réserver moins de 30 minutes à l\'avance');
        }
      }
    }
  }

  // Mettre à jour le statut d'une réservation
  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus newStatus, {
    String? reason,
  }) async {
    try {
      // Récupérer la réservation actuelle pour obtenir l'ancien statut et l'userId
      final reservationDoc = await _firestore
          .collection(_collection)
          .doc(reservationId)
          .get();
      if (!reservationDoc.exists) {
        throw Exception('Réservation non trouvée');
      }

      final reservationData = reservationDoc.data()!;
      final oldStatus = ReservationStatus.values.firstWhere(
        (status) => status.name == reservationData['status'],
        orElse: () => ReservationStatus.pending,
      );
      final userId = reservationData['userId'] as String;

      // Mettre à jour le statut
      await _firestore.collection(_collection).doc(reservationId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });

      // Envoyer une notification au client
      await _notificationService.notifyReservationStatusChanged(
        userId: userId,
        reservationId: reservationId,
        oldStatus: oldStatus,
        newStatus: newStatus,
        reason: reason,
      );
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

  // Mettre à jour un champ spécifique d'une réservation
  Future<void> updateReservationField(
    String reservationId,
    String fieldName,
    dynamic value,
  ) async {
    try {
      await _firestore.collection(_collection).doc(reservationId).update({
        fieldName: value,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du champ $fieldName: $e');
    }
  }

  // Obtenir les réservations en attente (pour les conducteurs/admin) avec pagination
  Future<List<Reservation>> getPendingReservations({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
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
        .where('status', isEqualTo: ReservationStatus.inProgress.name)
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
        .where('status', isEqualTo: ReservationStatus.completed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // ✅ OPTIMISÉ : Méthode générique pour enrichir les réservations avec les noms d'utilisateurs (avec cache)
  Future<Reservation> _enrichReservationWithUserName(
    Reservation reservation,
  ) async {
    if (reservation.userName != null && reservation.userName!.isNotEmpty) {
      return reservation;
    }

    // Vérifier le cache d'abord
    if (_userNameCache.containsKey(reservation.userId)) {
      return reservation.copyWith(userName: _userNameCache[reservation.userId]);
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

        // Mettre en cache le résultat
        _userNameCache[reservation.userId] = userName;
        return reservation.copyWith(userName: userName);
      }
    } catch (e) {
      // En cas d'erreur, garder le nom par défaut et le mettre en cache
      _userNameCache[reservation.userId] = 'Utilisateur';
    }

    return reservation.copyWith(userName: 'Utilisateur');
  }

  // ✅ Méthode générique pour les streams avec enrichissement des noms d'utilisateurs
  Stream<List<Reservation>> _getReservationsStreamByStatus(
    ReservationStatus status, {
    String? userId,
  }) {
    Query query = _firestore.collection(_collection);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    query = query
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true);

    return query.snapshots().asyncMap((snapshot) async {
      final reservations = <Reservation>[];
      for (var doc in snapshot.docs) {
        var reservation = Reservation.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
        reservation = await _enrichReservationWithUserName(reservation);
        reservations.add(reservation);
      }
      return reservations;
    });
  }

  // Stream des réservations en attente (pour les conducteurs)
  Stream<List<Reservation>> getPendingReservationsStream() {
    return _getReservationsStreamByStatus(ReservationStatus.pending);
  }

  // ✅ Stream des réservations confirmées (TOUTES - pour admin)
  Stream<List<Reservation>> getConfirmedReservationsStream() {
    return _getReservationsStreamByStatus(ReservationStatus.confirmed);
  }

  // ✅ Stream des réservations en cours (payées)
  Stream<List<Reservation>> getInProgressReservationsStream() {
    return _getReservationsStreamByStatus(ReservationStatus.inProgress);
  }

  // ✅ Stream des réservations terminées (TOUTES - pour admin)
  Stream<List<Reservation>> getCompletedReservationsStream() {
    return _getReservationsStreamByStatus(ReservationStatus.completed);
  }

  // Stream des réservations en attente pour un utilisateur spécifique
  Stream<List<Reservation>> getUserPendingReservationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _getReservationsStreamByStatus(
      ReservationStatus.pending,
      userId: currentUser.uid,
    );
  }

  // Supprimer une réservation
  Future<void> deleteReservation(String reservationId) async {
    try {
      await _firestore.collection(_collection).doc(reservationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la réservation: $e');
    }
  }

  // Obtenir toutes les réservations terminées (pour la suppression en masse)
  Future<List<Reservation>> getCompletedReservations() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: ReservationStatus.completed.name)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des réservations terminées: $e',
      );
    }
  }

  // Refuser une réservation avec une raison
  Future<void> refuseReservation(String reservationId, {String? reason}) async {
    await updateReservationStatus(
      reservationId,
      ReservationStatus.cancelled,
      reason: reason ?? 'Demande refusée par l\'administrateur',
    );
  }

  // Annuler une réservation confirmée avec une raison
  Future<void> cancelConfirmedReservation(
    String reservationId, {
    String? reason,
  }) async {
    await updateReservationStatus(
      reservationId,
      ReservationStatus.cancelled,
      reason: reason ?? 'Course annulée par l\'administrateur',
    );
  }

  // Accepter une réservation (mise en attente de paiement)
  Future<void> acceptReservation(String reservationId) async {
    await updateReservationStatus(reservationId, ReservationStatus.pending);
    // Ajouter un flag pour indiquer qu'elle est en attente de paiement
    await updateReservationField(reservationId, 'waitingForPayment', true);
    await updateReservationField(
      reservationId,
      'acceptedAt',
      DateTime.now().toIso8601String(),
    );
  }

  // Confirmer une réservation (après paiement)
  Future<void> confirmReservation(String reservationId) async {
    await updateReservationStatus(reservationId, ReservationStatus.confirmed);
  }

  // Marquer une réservation comme en cours
  Future<void> startReservation(String reservationId) async {
    await updateReservationStatus(reservationId, ReservationStatus.inProgress);
  }

  // Marquer une réservation comme terminée
  Future<void> completeReservation(String reservationId) async {
    await updateReservationStatus(reservationId, ReservationStatus.completed);
  }
}
