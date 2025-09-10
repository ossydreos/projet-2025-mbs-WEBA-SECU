import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vehicles';

  // Récupérer tous les véhicules actifs
  Future<List<VehiculeType>> getActiveVehicles() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .get();

      return snapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des véhicules: $e');
      return [];
    }
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
      print('Erreur lors de la récupération de tous les véhicules: $e');
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
      print('Erreur lors de la récupération du véhicule $id: $e');
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
      print('Erreur lors de la récupération des véhicules par catégorie: $e');
      return [];
    }
  }

  // Créer un nouveau véhicule
  Future<String?> createVehicle(VehiculeType vehicle) async {
    try {
      final docRef = await _firestore.collection(_collection).add(vehicle.toMap());
      
      // Mettre à jour l'ID du véhicule
      await _firestore.collection(_collection).doc(docRef.id).update({
        'id': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du véhicule: $e');
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
      print('Erreur lors de la mise à jour du véhicule: $e');
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
      print('Erreur lors de la suppression du véhicule: $e');
      return false;
    }
  }

  // Supprimer définitivement un véhicule
  Future<bool> permanentlyDeleteVehicle(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression définitive du véhicule: $e');
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
    return '${price.toStringAsFixed(2)} €';
  }
}
