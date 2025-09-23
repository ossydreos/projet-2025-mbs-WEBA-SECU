import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_offer.dart';

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
        durationHours: durationHours,
        durationMinutes: durationMinutes,
        clientNote: clientNote,
        status: CustomOfferStatus.pending,
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
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: CustomOfferStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomOffer.fromMap(doc.data()))
          .toList();
    });
  }

  // Accepter une offre (chauffeur)
  Future<void> acceptCustomOffer({
    required String offerId,
    required double proposedPrice,
    String? driverMessage,
    String? driverId,
    String? driverName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': CustomOfferStatus.accepted.name,
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

  // Rejeter une offre (chauffeur)
  Future<void> rejectCustomOffer({
    required String offerId,
    String? driverMessage,
    String? driverId,
    String? driverName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': CustomOfferStatus.rejected.name,
        'driverMessage': driverMessage,
        'driverId': driverId,
        'driverName': driverName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors du rejet de l\'offre: $e');
    }
  }

  // Confirmer une offre (client après acceptation)
  Future<void> confirmCustomOffer({
    required String offerId,
    required String paymentMethod,
  }) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': CustomOfferStatus.confirmed.name,
        'paymentMethod': paymentMethod,
        'confirmedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de la confirmation de l\'offre: $e');
    }
  }

  // Annuler une offre
  Future<void> cancelCustomOffer(String offerId) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': CustomOfferStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de l\'offre: $e');
    }
  }

  // Mettre à jour le statut d'une offre
  Future<void> updateOfferStatus({
    required String offerId,
    required CustomOfferStatus status,
  }) async {
    try {
      await _firestore.collection(_collection).doc(offerId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
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
  }) async {
    try {
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
