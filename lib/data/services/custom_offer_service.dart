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
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'offre: $e');
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
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation de l\'offre: $e');
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
    } catch (e) {
      throw Exception('Erreur lors du rejet de l\'offre: $e');
    }
  }


  // Marquer une offre comme en cours (après paiement)
  Future<void> startCustomOffer(String offerId) async {
    try {
      // Vérifier le statut actuel de l'offre avant de la démarrer
      final offerDoc = await _firestore.collection(_collection).doc(offerId).get();
      if (!offerDoc.exists) {
        print('❌ CustomOfferService: Offre $offerId non trouvée');
        throw Exception('Offre non trouvée');
      }
      
      final offerData = offerDoc.data()!;
      final currentStatus = offerData['status'] as String?;
      
      // Vérifier que l'offre est toujours confirmée (en attente de paiement)
      if (currentStatus != ReservationStatus.confirmed.name) {
        print('❌ CustomOfferService: Offre $offerId n\'est plus confirmée (statut: $currentStatus)');
        throw Exception('Cette offre a déjà été traitée ou annulée');
      }
      
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.inProgress.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('✅ CustomOfferService: Offre personnalisée $offerId démarrée avec succès');
    } catch (e) {
      print('❌ CustomOfferService: Erreur lors du démarrage de l\'offre: $e');
      throw Exception('Erreur lors du démarrage de l\'offre: $e');
    }
  }

  // Marquer une offre comme terminée
  Future<void> completeCustomOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.completed.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de la finalisation de l\'offre: $e');
    }
  }

  // Annuler une offre
  Future<void> cancelCustomOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': ReservationStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de l\'offre: $e');
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
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'ID de réservation de l\'offre: $e');
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
        print('❌ CustomOfferService: Offre $offerId non trouvée');
        throw Exception('Offre non trouvée');
      }
      
      final offerData = offerDoc.data()!;
      final currentStatus = offerData['status'] as String?;
      
      // Vérifier que l'offre est toujours en attente (pending) avant de la traiter
      if (currentStatus != ReservationStatus.pending.name) {
        print('❌ CustomOfferService: Offre $offerId n\'est plus en attente (statut: $currentStatus)');
        throw Exception('Cette offre a déjà été traitée ou annulée');
      }
      
      await _firestore.collection(_collection).doc(offerId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('✅ CustomOfferService: Statut de l\'offre $offerId mis à jour vers ${status.name}');
    } catch (e) {
      print('❌ CustomOfferService: Erreur lors de la mise à jour du statut: $e');
      throw Exception('Erreur lors de la mise à jour du statut: $e');
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
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'offre: $e');
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
        print('❌ CustomOfferService: Offre $offerId non trouvée');
        throw Exception('Offre non trouvée');
      }
      
      final offerData = offerDoc.data()!;
      final currentStatus = offerData['status'] as String?;
      
      // Vérifier que l'offre est toujours en attente (pending) avant de la confirmer
      if (status == 'confirmed' && currentStatus != ReservationStatus.pending.name) {
        print('❌ CustomOfferService: Offre $offerId n\'est plus en attente (statut: $currentStatus)');
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
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'offre: $e');
    }
  }

  // Supprimer une offre (pour les tests ou nettoyage)
  Future<void> deleteCustomOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'offre: $e');
    }
  }
}
