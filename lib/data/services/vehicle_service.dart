import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vehicles';

  // Récupérer tous les véhicules actifs avec pagination
  Future<List<VehiculeType>> getActiveVehicles({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .orderBy('name')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log(
        'Erreur lors de la récupération des véhicules: $e',
        name: 'VehicleService',
        error: e,
      );
      return [];
    }
  }

  // Stream des véhicules en temps réel
  Stream<List<VehiculeType>> getVehiclesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }


  // Récupérer tous les véhicules (actifs et inactifs)
  Future<List<VehiculeType>> getAllVehicles() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('category')
          .get();

      return snapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log(
        'Erreur lors de la récupération de tous les véhicules: $e',
        name: 'VehicleService',
        error: e,
      );
      return [];
    }
  }

  // Récupérer un véhicule par ID
  Future<VehiculeType?> getVehicleById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (doc.exists) {
        return VehiculeType.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      developer.log(
        'Erreur lors de la récupération du véhicule $id: $e',
        name: 'VehicleService',
        error: e,
      );
      return null;
    }
  }

  // Récupérer les véhicules par catégorie
  Future<List<VehiculeType>> getVehiclesByCategory(VehicleCategory category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log(
        'Erreur lors de la récupération des véhicules par catégorie: $e',
        name: 'VehicleService',
        error: e,
      );
      return [];
    }
  }

  // Créer un nouveau véhicule
  Future<String?> createVehicle(VehiculeType vehicle) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final vehicleWithId = vehicle.copyWith(id: docRef.id);
      
      await docRef.set(vehicleWithId.toMap());
      return docRef.id;
    } catch (e) {
      developer.log(
        'Erreur lors de la création du véhicule: $e',
        name: 'VehicleService',
        error: e,
      );
      return null;
    }
  }

  // Mettre à jour un véhicule
  Future<bool> updateVehicle(VehiculeType vehicle) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(vehicle.id)
          .update(vehicle.copyWith(updatedAt: DateTime.now()).toMap());
      return true;
    } catch (e) {
      developer.log(
        'Erreur lors de la mise à jour du véhicule: $e',
        name: 'VehicleService',
        error: e,
      );
      return false;
    }
  }

  // Supprimer un véhicule (soft delete)
  Future<bool> deleteVehicle(String id) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      developer.log(
        'Erreur lors de la suppression du véhicule: $e',
        name: 'VehicleService',
        error: e,
      );
      return false;
    }
  }

  // Supprimer définitivement un véhicule
  Future<bool> permanentlyDeleteVehicle(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      developer.log(
        'Erreur lors de la suppression définitive du véhicule: $e',
        name: 'VehicleService',
        error: e,
      );
      return false;
    }
  }


  // Calculer le prix d'un trajet
  double calculateTripPrice(VehiculeType vehicle, double distanceInKm) {
    return vehicle.pricePerKm * distanceInKm;
  }

  // Obtenir le prix formaté d'un trajet
  String getFormattedTripPrice(VehiculeType vehicle, double distanceInKm) {
    final price = calculateTripPrice(vehicle, distanceInKm);
    // ✅ Arrondir à 0.05 CHF près et afficher 2 décimales
    final roundedPrice = (price * 20).round() / 20;
    return '${roundedPrice.toStringAsFixed(2)} CHF';
  }
}
