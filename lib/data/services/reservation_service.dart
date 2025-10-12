import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation.dart';
import '../models/reservation_filter.dart';
import 'client_notification_service.dart';
import 'ride_chat_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ClientNotificationService _notificationService =
      ClientNotificationService();
  final RideChatService _chatService = RideChatService();

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
      // La validation temporelle est déjà faite au moment de la sélection de l'heure
      // dans le scheduling screen, pas besoin de la refaire ici
      
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

      // Supprimer le thread de chat si la réservation est terminée ou annulée
      if (newStatus == ReservationStatus.completed || newStatus == ReservationStatus.cancelled) {
        try {
          await _chatService.deleteThreadForReservation(reservationId);
        } catch (e) {
          // Log l'erreur mais ne pas faire échouer la mise à jour du statut
          print('Erreur lors de la suppression du thread de chat: $e');
        }
      }
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
              .map(
                (doc) => Reservation.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              )
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
              .map(
                (doc) => Reservation.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              )
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
              .map(
                (doc) => Reservation.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              )
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
    print(
      '🗑️ ReservationService: Suppression de la réservation $reservationId',
    );
    try {
      await _firestore.collection(_collection).doc(reservationId).delete();
      print('✅ ReservationService: Réservation supprimée avec succès');
    } catch (e) {
      print('❌ ReservationService: Erreur lors de la suppression: $e');
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
    // Mettre à jour le statut de la réservation à "confirmed"
    await updateReservationStatus(reservationId, ReservationStatus.confirmed);

    // Marquer comme payé (car l'admin accepte = le client doit payer)
    await updateReservationField(reservationId, 'isPaid', true);

    // Ajouter un flag pour indiquer qu'elle est en attente de paiement
    await updateReservationField(reservationId, 'waitingForPayment', true);
    await updateReservationField(
      reservationId,
      'acceptedAt',
      DateTime.now().toIso8601String(),
    );
  }

  // Récupérer une réservation par son ID
  Future<Reservation?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(reservationId)
          .get();
      if (doc.exists) {
        return Reservation.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la réservation: $e');
      return null;
    }
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
    await _firestore.collection(_collection).doc(reservationId).update({
      'status': ReservationStatus.completed.name,
      'isCompleted': true, // Marquer comme terminé
      'lastUpdated': Timestamp.now(),
    });
  }

  // ✅ Nouvelles méthodes de filtrage avancé

  /// Obtenir les réservations avec filtres avancés
  Future<List<Reservation>> getReservationsWithFilter(
    ReservationFilter filter,
  ) async {
    try {
      Query query = _firestore.collection(_collection);

      // Filtrer par statut selon le type de réservation (à venir vs terminées)
      if (filter.isUpcoming) {
        // Pour les courses à venir : pending, confirmed, inProgress
        query = query.where(
          'status',
          whereIn: [
            ReservationStatus.pending.name,
            ReservationStatus.confirmed.name,
            ReservationStatus.inProgress.name,
          ],
        );
      } else {
        // Pour les courses terminées : completed, cancelled
        query = query.where(
          'status',
          whereIn: [
            ReservationStatus.completed.name,
            ReservationStatus.cancelled.name,
          ],
        );
      }

      // Appliquer les filtres spécifiques
      switch (filter.filterType) {
        case ReservationFilterType.demand:
          query = query.where(
            'status',
            isEqualTo: ReservationStatus.pending.name,
          );
          break;
        case ReservationFilterType.counterOffer:
          query = query.where('hasCounterOffer', isEqualTo: true);
          break;
        case ReservationFilterType.dateRange:
          if (filter.startDate != null) {
            query = query.where(
              'selectedDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
            );
          }
          if (filter.endDate != null) {
            final endDate = DateTime(
              filter.endDate!.year,
              filter.endDate!.month,
              filter.endDate!.day,
              23,
              59,
              59,
              999,
              999,
            );
            query = query.where(
              'selectedDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            );
          }
          break;
        case ReservationFilterType.all:
          break;
      }

      // Filtrer par type de réservation si demandé
      if (filter.typeFilter != ReservationTypeFilter.all) {
        switch (filter.typeFilter) {
          case ReservationTypeFilter.reservation:
            query = query.where('type', isEqualTo: 'reservation');
            break;
          case ReservationTypeFilter.offer:
            query = query.where('type', isEqualTo: 'offer');
            break;
          case ReservationTypeFilter.all:
            break;
        }
      }

      // Trier par défaut par date de création (descendant)
      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      final reservations = querySnapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Enrichir avec les noms d'utilisateurs
      final enrichedReservations = <Reservation>[];
      for (var reservation in reservations) {
        final enriched = await _enrichReservationWithUserName(reservation);
        enrichedReservations.add(enriched);
      }

      // Appliquer le tri final côté client
      return filter.applyFilter(enrichedReservations);
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des réservations filtrées: $e',
      );
    }
  }

  /// Stream des réservations avec filtres avancés
  Stream<List<Reservation>> getReservationsStreamWithFilter(
    ReservationFilter filter,
  ) {
    Query query = _firestore.collection(_collection);

    // Requête simple pour éviter les index complexes
    // On récupère toutes les réservations de l'utilisateur et on filtre côté client
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().asyncMap((snapshot) async {
      final reservations = snapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Enrichir avec les noms d'utilisateurs
      final enrichedReservations = <Reservation>[];
      for (var reservation in reservations) {
        final enriched = await _enrichReservationWithUserName(reservation);
        enrichedReservations.add(enriched);
      }

      // Appliquer le tri final côté client
      return filter.applyFilter(enrichedReservations);
    });
  }

  /// Obtenir les réservations terminées avec filtres
  Future<List<Reservation>> getCompletedReservationsWithFilter(
    ReservationFilter filter,
  ) async {
    final completedFilter = filter.copyWith(isUpcoming: false);
    return getReservationsWithFilter(completedFilter);
  }

  /// Obtenir les réservations à venir avec filtres
  Future<List<Reservation>> getUpcomingReservationsWithFilter(
    ReservationFilter filter,
  ) async {
    final upcomingFilter = filter.copyWith(isUpcoming: true);
    return getReservationsWithFilter(upcomingFilter);
  }

  /// Stream des réservations terminées avec filtres
  Stream<List<Reservation>> getCompletedReservationsStreamWithFilter(
    ReservationFilter filter,
  ) {
    final completedFilter = filter.copyWith(isUpcoming: false);
    return getReservationsStreamWithFilter(completedFilter);
  }

  /// Stream des réservations à venir avec filtres
  Stream<List<Reservation>> getUpcomingReservationsStreamWithFilter(
    ReservationFilter filter,
  ) {
    final upcomingFilter = filter.copyWith(isUpcoming: true);
    return getReservationsStreamWithFilter(upcomingFilter);
  }

  // ✅ Nouvelles méthodes pour les utilisateurs avec filtres

  /// Obtenir les réservations d'un utilisateur avec filtres avancés
  Future<List<Reservation>> getUserReservationsWithFilter(
    String userId,
    ReservationFilter filter,
  ) async {
    try {
      Query query = _firestore.collection(_collection);

      // Filtrer par utilisateur
      query = query.where('userId', isEqualTo: userId);

      // Filtrer par statut selon le type de réservation (à venir vs terminées)
      if (filter.isUpcoming) {
        // Pour les courses à venir : pending, confirmed, inProgress
        query = query.where(
          'status',
          whereIn: [
            ReservationStatus.pending.name,
            ReservationStatus.confirmed.name,
            ReservationStatus.inProgress.name,
          ],
        );
      } else {
        // Pour les courses terminées : completed, cancelled
        query = query.where(
          'status',
          whereIn: [
            ReservationStatus.completed.name,
            ReservationStatus.cancelled.name,
          ],
        );
      }

      // Appliquer les filtres spécifiques
      switch (filter.filterType) {
        case ReservationFilterType.demand:
          query = query.where(
            'status',
            isEqualTo: ReservationStatus.pending.name,
          );
          break;
        case ReservationFilterType.counterOffer:
          query = query.where('hasCounterOffer', isEqualTo: true);
          break;
        case ReservationFilterType.dateRange:
          if (filter.startDate != null) {
            query = query.where(
              'selectedDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
            );
          }
          if (filter.endDate != null) {
            final endDate = DateTime(
              filter.endDate!.year,
              filter.endDate!.month,
              filter.endDate!.day,
              23,
              59,
              59,
              999,
              999,
            );
            query = query.where(
              'selectedDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            );
          }
          break;
        case ReservationFilterType.all:
          break;
      }

      // Filtrer par type de réservation si demandé
      if (filter.typeFilter != ReservationTypeFilter.all) {
        switch (filter.typeFilter) {
          case ReservationTypeFilter.reservation:
            query = query.where('type', isEqualTo: 'reservation');
            break;
          case ReservationTypeFilter.offer:
            query = query.where('type', isEqualTo: 'offer');
            break;
          case ReservationTypeFilter.all:
            break;
        }
      }

      // Trier par défaut par date de création (descendant)
      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      final reservations = querySnapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Enrichir avec les noms d'utilisateurs
      final enrichedReservations = <Reservation>[];
      for (var reservation in reservations) {
        final enriched = await _enrichReservationWithUserName(reservation);
        enrichedReservations.add(enriched);
      }

      // Appliquer le tri final côté client
      return filter.applyFilter(enrichedReservations);
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des réservations filtrées: $e',
      );
    }
  }

  /// Stream des réservations d'un utilisateur avec filtres avancés
  Stream<List<Reservation>> getUserReservationsStreamWithFilter(
    String userId,
    ReservationFilter filter,
  ) {
    Query query = _firestore.collection(_collection);

    // Filtrer par utilisateur
    query = query.where('userId', isEqualTo: userId);

    // Requête simple pour éviter les index complexes
    // On récupère toutes les réservations de l'utilisateur et on filtre côté client
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().asyncMap((snapshot) async {
      final reservations = snapshot.docs
          .map(
            (doc) => Reservation.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Enrichir avec les noms d'utilisateurs
      final enrichedReservations = <Reservation>[];
      for (var reservation in reservations) {
        final enriched = await _enrichReservationWithUserName(reservation);
        enrichedReservations.add(enriched);
      }

      // Appliquer le tri final côté client
      return filter.applyFilter(enrichedReservations);
    });
  }


  /// Obtenir les réservations terminées d'un utilisateur avec filtres
  Future<List<Reservation>> getUserCompletedReservationsWithFilter(
    String userId,
    ReservationFilter filter,
  ) async {
    final completedFilter = filter.copyWith(isUpcoming: false);
    return getUserReservationsWithFilter(userId, completedFilter);
  }

  /// Obtenir les réservations à venir d'un utilisateur avec filtres
  Future<List<Reservation>> getUserUpcomingReservationsWithFilter(
    String userId,
    ReservationFilter filter,
  ) async {
    final upcomingFilter = filter.copyWith(isUpcoming: true);
    return getUserReservationsWithFilter(userId, upcomingFilter);
  }

  /// Stream des réservations terminées d'un utilisateur avec filtres
  Stream<List<Reservation>> getUserCompletedReservationsStreamWithFilter(
    String userId,
    ReservationFilter filter,
  ) {
    final completedFilter = filter.copyWith(isUpcoming: false);
    return getUserReservationsStreamWithFilter(userId, completedFilter);
  }

  /// Stream des réservations à venir d'un utilisateur avec filtres
  Stream<List<Reservation>> getUserUpcomingReservationsStreamWithFilter(
    String userId,
    ReservationFilter filter,
  ) {
    final upcomingFilter = filter.copyWith(isUpcoming: true);
    return getUserReservationsStreamWithFilter(userId, upcomingFilter);
  }
}
