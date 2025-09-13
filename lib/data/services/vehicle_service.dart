import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';
import 'package:my_mobility_services/data/models/vehicle_category.dart';
import 'package:my_mobility_services/data/models/vehicle_with_category_status.dart';
import 'package:my_mobility_services/data/services/vehicle_category_service.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vehicles';
  final VehicleCategoryService _categoryService = VehicleCategoryService();

  // Récupérer tous les véhicules actifs (en tenant compte des catégories désactivées)
  Future<List<VehiculeType>> getActiveVehicles() async {
    try {
      // Récupérer les catégories actives
      final activeCategories = await _categoryService.getActiveCategories();
      final activeCategoryNames = activeCategories.map((c) => c.name).toSet();

      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .get();

      // Filtrer les véhicules dont la catégorie est active
      final vehicles = snapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data() as Map<String, dynamic>))
          .where((vehicle) => activeCategoryNames.contains(vehicle.category.name))
          .toList();

      return vehicles;
    } catch (e) {
      print('Erreur lors de la récupération des véhicules: $e');
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

  // Récupérer tous les véhicules (y compris ceux des catégories désactivées)
  Future<List<VehiculeType>> getAllVehiclesWithCategoryStatus() async {
    try {
      // Récupérer toutes les catégories
      final allCategories = await _categoryService.getAllCategories();
      final categoryMap = {for (var c in allCategories) c.name: c};

      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .get();

      final vehicles = snapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Marquer les véhicules des catégories désactivées
      for (var vehicle in vehicles) {
        final category = categoryMap[vehicle.category.name];
        if (category != null && !category.isActive) {
          // Créer une copie du véhicule avec la catégorie marquée comme inactive
          // Note: On pourrait ajouter un champ isCategoryActive au modèle VehiculeType
        }
      }

      return vehicles;
    } catch (e) {
      print('Erreur lors de la récupération de tous les véhicules: $e');
      return [];
    }
  }

  // Stream pour récupérer les véhicules en temps réel avec statut des catégories
  Stream<List<VehicleWithCategoryStatus>> getVehiclesWithCategoryStatusStream() {
    final StreamController<List<VehicleWithCategoryStatus>> controller = StreamController.broadcast();
    Map<String, VehicleCategoryModel> categoryCache = {};
    List<VehiculeType> vehicleCache = [];

    // Fonction pour mettre à jour le stream
    void updateStream() async {
      try {
        final vehicles = vehicleCache.map((vehicle) {
          final category = categoryCache[vehicle.category.name];
          final isCategoryActive = category?.isActive ?? true;
          
          return VehicleWithCategoryStatus(
            vehicle: vehicle,
            isCategoryActive: isCategoryActive,
            categoryInfo: category,
          );
        }).toList();

        // Éviter les mises à jour inutiles
        if (!controller.isClosed) {
          controller.add(vehicles);
        }
      } catch (e) {
        print('Erreur lors de la mise à jour du stream: $e');
        if (!controller.isClosed) {
          controller.add(<VehicleWithCategoryStatus>[]);
        }
      }
    }

    // Écouter les changements de véhicules
    _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .listen((vehiclesSnapshot) {
      vehicleCache = vehiclesSnapshot.docs
          .map((doc) => VehiculeType.fromMap(doc.data()))
          .toList();
      updateStream();
    });

    // Écouter les changements de catégories
    _firestore
        .collection('vehicle_categories')
        .snapshots()
        .listen((categoriesSnapshot) {
      categoryCache = {
        for (var doc in categoriesSnapshot.docs)
          doc.data()['name']: VehicleCategoryModel.fromMap(doc.data())
      };
      updateStream();
    });

    return controller.stream;
  }

  // Stream pour récupérer les catégories en temps réel
  Stream<List<VehicleCategoryModel>> getCategoriesStream() {
    return _firestore
        .collection('vehicle_categories')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleCategoryModel.fromMap(doc.data()))
            .toList());
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
