import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_offer.dart';
import '../models/reservation.dart'; // Import pour utiliser ReservationStatus

class CustomOfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection pour les offres personnalisées
  static const String _collection = 'custom_offers';

  // Créer une nouvelle offre personnalisée
  Future<String> createCustomOffer({
    required String departure,
    required String destination,
    required int durationHours,
    required int durationMinutes,
    String? vehicleId,
    String? vehicleName,
    String? clientNote,
    Map<String, dynamic>? departureCoordinates,
    Map<String, dynamic>? destinationCoordinates,
    DateTime? startDateTime,
    DateTime? endDateTime,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final now = DateTime.now();

      if (startDateTime != null && startDateTime.isBefore(now)) {
        throw Exception('Impossible de créer une offre personnalisée dans le passé');
      }

      if (endDateTime != null) {
        if (startDateTime != null && endDateTime.isBefore(startDateTime)) {
          throw Exception('La date de fin doit être postérieure à la date de début');
        }
        if (endDateTime.isBefore(now)) {
          throw Exception('La date de fin ne peut pas être dans le passé');
        }
      }

      // Générer un ID unique pour l'offre
      final offerId = _firestore.collection(_collection).doc().id;

      final customOffer = CustomOffer(
        id: offerId,
        userId: user.uid,
        userName: user.displayName,
        departure: departure,
        destination: destination,
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        durationHours: durationHours,
        durationMinutes: durationMinutes,
        clientNote: clientNote,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        departureCoordinates: departureCoordinates,
        destinationCoordinates: destinationCoordinates,
      );

      // Sauvegarder dans Firebase
      await _firestore
          .collection(_collection)
          .doc(offerId)
          .set(customOffer.toMap());

      return offerId;
    } catch (e, stackTrace) {
      // CWE-209 CORRIGÉ : Log serveur uniquement
      developer.log(
        'Error creating custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de créer l\'offre');
    }
  }

  // Récupérer les offres d'un utilisateur
  Stream<List<CustomOffer>> getUserCustomOffers() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) => CustomOffer.fromMap(doc.data()))
          .toList();
      
      // Trier par date de création (plus récent en premier)
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return offers;
    });
  }

  // Récupérer toutes les offres (pour les admins/chauffeurs)
  Stream<List<CustomOffer>> getAllCustomOffers() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomOffer.fromMap(doc.data()))
          .toList();
    });
  }

  // Stream pour les offres (pour l'admin)
  Stream<QuerySnapshot> getCustomOffersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Récupérer les offres en attente (pour les chauffeurs)
  Stream<List<CustomOffer>> getPendingCustomOffers() {
    // Pas d'ordre pour éviter l'index composite requis; tri côté client
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomOffer.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Récupérer les offres en attente d'action admin (pending + confirmed)
  Stream<List<CustomOffer>> getCustomOffersForAdmin() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomOffer.fromMap(doc.data()))
          .where((offer) => 
              offer.status == ReservationStatus.pending ||
              offer.status == ReservationStatus.confirmed)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Accepter une offre (chauffeur) - passe à "confirmed" comme les réservations
  Future<void> acceptCustomOffer({
    required String offerId,
    required double proposedPrice,
    String? driverMessage,
    String? driverId,
    String? driverName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.confirmed.name, // Passe à confirmed
        'proposedPrice': proposedPrice,
        'driverMessage': driverMessage,
        'driverId': driverId,
        'driverName': driverName,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error accepting custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible d\'accepter l\'offre');
    }
  }

  // Rejeter une offre (chauffeur) - passe à "cancelled"
  Future<void> rejectCustomOffer({
    required String offerId,
    String? driverMessage,
    String? driverId,
    String? driverName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.cancelled.name,
        'driverMessage': driverMessage,
        'driverId': driverId,
        'driverName': driverName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error rejecting custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de refuser l\'offre');
    }
  }


  // Marquer une offre comme en cours (après paiement)
  Future<void> startCustomOffer(String offerId) async {
    try {
      // Vérifier le statut actuel de l'offre avant de la démarrer
      final offerDoc = await _firestore.collection(_collection).doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offre non trouvée');
      }
      
      final offerData = offerDoc.data()!;
      final currentStatus = offerData['status'] as String?;
      
      // Vérifier que l'offre est toujours confirmée (en attente de paiement)
      if (currentStatus != ReservationStatus.confirmed.name) {
        throw Exception('Cette offre a déjà été traitée ou annulée');
      }
      
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.inProgress.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
    } catch (e, stackTrace) {
      developer.log(
        'Error starting custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de démarrer l\'offre');
    }
  }

  // Marquer une offre comme terminée
  Future<void> completeCustomOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.completed.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error completing custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de finaliser l\'offre');
    }
  }

  // Annuler une offre
  Future<void> cancelCustomOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error cancelling custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible d\'annuler l\'offre');
    }
  }

  // Mettre à jour l'ID de réservation d'une offre personnalisée
  Future<void> updateCustomOfferReservationId({
    required String offerId,
    required String reservationId,
  }) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'reservationId': reservationId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error updating offer reservation ID',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de lier l\'offre à la réservation');
    }
  }

  // Mettre à jour le statut d'une offre
  Future<void> updateOfferStatus({
    required String offerId,
    required ReservationStatus status,
  }) async {
    try {
      // Vérifier le statut actuel de l'offre avant de la mettre à jour
      final offerDoc = await _firestore.collection(_collection).doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offre non trouvée');
      }
      
      final offerData = offerDoc.data()!;
      final currentStatus = offerData['status'] as String?;
      
      if (currentStatus == null) {
        throw Exception('Statut actuel introuvable');
      }

      final currentStatusEnum = ReservationStatus.values.firstWhere(
        (s) => s.name == currentStatus,
        orElse: () => throw Exception('Statut de l\'offre invalide'),
      );

      const allowedTransitions = {
        ReservationStatus.pending: {
          ReservationStatus.confirmed,
          ReservationStatus.cancelled,
        },
        ReservationStatus.confirmed: {
          ReservationStatus.inProgress,
          ReservationStatus.cancelled,
        },
        ReservationStatus.inProgress: {
          ReservationStatus.completed,
          ReservationStatus.cancelled,
        },
      };

      final canTransition = allowedTransitions[currentStatusEnum]?.contains(status) ?? false;
      if (!canTransition) {
        throw Exception('Transition de statut non autorisée pour cette offre');
      }

      await _firestore.collection(_collection).doc(offerId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
    } catch (e, stackTrace) {
      developer.log(
        'Error updating offer status',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de mettre à jour le statut');
    }
  }

  // Récupérer une offre par son ID
  Future<CustomOffer?> getCustomOfferById(String offerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(offerId).get();
      if (doc.exists) {
        return CustomOffer.fromMap(doc.data()!);
      }
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Mettre à jour une offre personnalisée (pour l'admin)
  Future<void> updateCustomOffer(
    String offerId, {
    String? status,
    double? proposedPrice,
    String? driverMessage,
    String? driverId,
    String? driverName,
    int? durationHours,
    int? durationMinutes,
    String? reservationId,
  }) async {
    try {
      // Vérifier le statut actuel de l'offre avant de la mettre à jour
      final offerDoc = await _firestore.collection(_collection).doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offre non trouvée');
      }
      
      final offerData = offerDoc.data()!;
      final currentStatus = offerData['status'] as String?;
      
      // Vérifier que l'offre est toujours en attente (pending) avant de la confirmer
      if (status == 'confirmed' && currentStatus != ReservationStatus.pending.name) {
        throw Exception('Cette offre a déjà été traitée ou annulée');
      }
      
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status != null) {
        updateData['status'] = status;
      }
      if (proposedPrice != null) {
        updateData['proposedPrice'] = proposedPrice;
      }
      if (driverMessage != null) {
        updateData['driverMessage'] = driverMessage;
      }
      if (driverId != null) {
        updateData['driverId'] = driverId;
      }
      if (driverName != null) {
        updateData['driverName'] = driverName;
      }
      if (durationHours != null) {
        updateData['durationHours'] = durationHours;
      }
      if (durationMinutes != null) {
        updateData['durationMinutes'] = durationMinutes;
      }
      if (reservationId != null) {
        updateData['reservationId'] = reservationId;
      }

      // Ajouter la date d'acceptation/rejet si le statut change
      if (status == 'accepted') {
        updateData['acceptedAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == 'rejected') {
        updateData['rejectedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore.collection(_collection).doc(offerId).update(updateData);
    } catch (e, stackTrace) {
      developer.log(
        'Error updating custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de mettre à jour l\'offre');
    }
  }

  // Supprimer une offre (pour les tests ou nettoyage)
  Future<void> deleteCustomOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).delete();
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting custom offer',
        name: 'CustomOfferService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de supprimer l\'offre');
    }
  }
}
