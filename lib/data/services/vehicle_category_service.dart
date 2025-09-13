import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/vehicle_category.dart';

class VehicleCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vehicle_categories';

  // Récupérer toutes les catégories
  Future<List<VehicleCategoryModel>> getAllCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => VehicleCategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // Récupérer les catégories actives seulement
  Future<List<VehicleCategoryModel>> getActiveCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => VehicleCategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des catégories actives: $e');
      return [];
    }
  }

  // Récupérer une catégorie par ID
  Future<VehicleCategoryModel?> getCategoryById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (doc.exists) {
        return VehicleCategoryModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la catégorie $id: $e');
      return null;
    }
  }

  // Créer une nouvelle catégorie
  Future<String?> createCategory(VehicleCategoryModel category) async {
    try {
      final docRef = await _firestore.collection(_collection).add(category.toMap());
      
      // Mettre à jour l'ID de la catégorie
      await _firestore.collection(_collection).doc(docRef.id).update({
        'id': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la catégorie: $e');
      return null;
    }
  }

  // Mettre à jour une catégorie
  Future<bool> updateCategory(VehicleCategoryModel category) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(category.id)
          .update(category.copyWith(updatedAt: DateTime.now()).toMap());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la catégorie: $e');
      return false;
    }
  }

  // Activer/désactiver une catégorie
  Future<bool> toggleCategoryStatus(String id, bool isActive) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Erreur lors du changement de statut de la catégorie: $e');
      return false;
    }
  }

  // Supprimer une catégorie (soft delete)
  Future<bool> deleteCategory(String id) async {
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
      print('Erreur lors de la suppression de la catégorie: $e');
      return false;
    }
  }

  // Supprimer définitivement une catégorie
  Future<bool> permanentlyDeleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression définitive de la catégorie: $e');
      return false;
    }
  }

  // Initialiser les catégories par défaut
  // Stream des catégories en temps réel
  Stream<List<VehicleCategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleCategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> initializeDefaultCategories() async {
    try {
      // Vérifier si des catégories existent déjà
      final existingCategories = await getAllCategories();
      if (existingCategories.isNotEmpty) return;

      // Créer les catégories par défaut
      final defaultCategories = [
        VehicleCategoryModel(
          id: '',
          name: 'economique',
          displayName: 'Économique',
          pricePerKm: 1.50,
          isActive: true,
          description: 'Véhicules économiques pour les trajets courts',
          icon: Icons.directions_car_outlined,
          maxPassengers: 4,
          maxLuggage: 2,
          createdAt: DateTime.now(),
        ),
        VehicleCategoryModel(
          id: '',
          name: 'van',
          displayName: 'Van',
          pricePerKm: 2.00,
          isActive: true,
          description: 'Vans pour les groupes et bagages volumineux',
          icon: Icons.airport_shuttle,
          maxPassengers: 8,
          maxLuggage: 4,
          createdAt: DateTime.now(),
        ),
        VehicleCategoryModel(
          id: '',
          name: 'luxe',
          displayName: 'Luxe',
          pricePerKm: 3.00,
          isActive: true,
          description: 'Véhicules de luxe pour un confort maximal',
          icon: Icons.directions_car,
          maxPassengers: 4,
          maxLuggage: 3,
          createdAt: DateTime.now(),
        ),
      ];

      for (final category in defaultCategories) {
        await createCategory(category);
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des catégories par défaut: $e');
    }
  }
}
