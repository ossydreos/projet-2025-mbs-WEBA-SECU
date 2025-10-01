import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/favorite_trip.dart';

/// Service pour gérer les trajets favoris
class FavoriteTripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection Firestore pour les trajets favoris
  static const String _collection = 'favorite_trips';

  /// Obtenir l'utilisateur actuel
  User? get _currentUser => _auth.currentUser;

  /// Obtenir tous les trajets favoris de l'utilisateur connecté
  Stream<List<FavoriteTrip>> getFavoriteTrips() {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      final trips = snapshot.docs.map((doc) => FavoriteTrip.fromFirestore(doc)).toList();
      // Trier localement par date de création (plus récent en premier)
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trips;
    });
  }

  /// Ajouter un nouveau trajet favori
  Future<String> addFavoriteTrip({
    required String departureAddress,
    required String arrivalAddress,
    required IconData icon,
    required String name,
    LatLng? departureCoordinates,
    LatLng? arrivalCoordinates,
  }) async {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final favoriteTrip = FavoriteTrip(
        id: '', // Sera généré par Firestore
        userId: _currentUser!.uid,
        departureAddress: departureAddress,
        arrivalAddress: arrivalAddress,
        icon: icon,
        name: name,
        createdAt: DateTime.now(),
        departureCoordinates: departureCoordinates,
        arrivalCoordinates: arrivalCoordinates,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(favoriteTrip.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du trajet favori: $e');
    }
  }

  /// Mettre à jour un trajet favori existant
  Future<void> updateFavoriteTrip({
    required String id,
    required String departureAddress,
    required String arrivalAddress,
    required IconData icon,
    required String name,
    LatLng? departureCoordinates,
    LatLng? arrivalCoordinates,
  }) async {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      await _firestore.collection(_collection).doc(id).update({
        'departureAddress': departureAddress,
        'arrivalAddress': arrivalAddress,
        'icon': _getStringFromIcon(icon),
        'name': name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'departureCoordinates': departureCoordinates != null ? {
          'latitude': departureCoordinates.latitude,
          'longitude': departureCoordinates.longitude,
        } : null,
        'arrivalCoordinates': arrivalCoordinates != null ? {
          'latitude': arrivalCoordinates.latitude,
          'longitude': arrivalCoordinates.longitude,
        } : null,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du trajet favori: $e');
    }
  }

  /// Supprimer un trajet favori
  Future<void> deleteFavoriteTrip(String id) async {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // Vérifier que le trajet appartient à l'utilisateur connecté
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Trajet favori non trouvé');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUser!.uid) {
        throw Exception('Vous n\'avez pas l\'autorisation de supprimer ce trajet');
      }

      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du trajet favori: $e');
    }
  }

  /// Obtenir un trajet favori par son ID
  Future<FavoriteTrip?> getFavoriteTripById(String id) async {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != _currentUser!.uid) {
        throw Exception('Vous n\'avez pas l\'autorisation d\'accéder à ce trajet');
      }

      return FavoriteTrip.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du trajet favori: $e');
    }
  }

  /// Vérifier si un trajet existe déjà (même départ et arrivée)
  Future<bool> tripExists({
    required String departureAddress,
    required String arrivalAddress,
    String? excludeId, // Pour exclure un trajet lors de la modification
  }) async {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('departureAddress', isEqualTo: departureAddress)
          .where('arrivalAddress', isEqualTo: arrivalAddress);

      final snapshot = await query.get();
      
      if (excludeId != null) {
        // Exclure le trajet en cours de modification
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du trajet: $e');
    }
  }

  /// Obtenir le nombre de trajets favoris de l'utilisateur
  Future<int> getFavoriteTripsCount() async {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des trajets favoris: $e');
    }
  }

  /// Rechercher des trajets favoris par nom ou adresse
  Stream<List<FavoriteTrip>> searchFavoriteTrips(String query) {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    if (query.isEmpty) {
      return getFavoriteTrips();
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      final allTrips = snapshot.docs
          .map((doc) => FavoriteTrip.fromFirestore(doc))
          .toList();

      // Trier localement par date de création (plus récent en premier)
      allTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Filtrer localement car Firestore ne supporte pas la recherche textuelle complexe
      return allTrips.where((trip) {
        final searchQuery = query.toLowerCase();
        return trip.name.toLowerCase().contains(searchQuery) ||
               trip.departureAddress.toLowerCase().contains(searchQuery) ||
               trip.arrivalAddress.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }


  /// Réorganiser les trajets favoris (changer l'ordre)
  Future<void> reorderFavoriteTrips(List<String> tripIds) async {
    if (_currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (int i = 0; i < tripIds.length; i++) {
        final docRef = _firestore.collection(_collection).doc(tripIds[i]);
        batch.update(docRef, {
          'order': i,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la réorganisation des trajets: $e');
    }
  }

  /// Convertir IconData en String pour Firestore
  static String _getStringFromIcon(IconData icon) {
    // Utiliser une comparaison directe des icônes
    if (icon == Icons.home) return 'home';
    if (icon == Icons.work) return 'work';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.place) return 'place';
    if (icon == Icons.location_on) return 'location_on';
    if (icon == Icons.location_city) return 'location_city';
    if (icon == Icons.local_hospital) return 'local_hospital';
    if (icon == Icons.local_grocery_store) return 'local_grocery_store';
    if (icon == Icons.local_restaurant) return 'local_restaurant';
    if (icon == Icons.local_cafe) return 'local_cafe';
    if (icon == Icons.local_gas_station) return 'local_gas_station';
    if (icon == Icons.local_parking) return 'local_parking';
    if (icon == Icons.local_pharmacy) return 'local_pharmacy';
    if (icon == Icons.local_post_office) return 'local_post_office';
    if (icon == Icons.local_shipping) return 'local_shipping';
    if (icon == Icons.local_taxi) return 'local_taxi';
    if (icon == Icons.local_airport) return 'local_airport';
    if (icon == Icons.local_atm) return 'local_atm';
    if (icon == Icons.local_bar) return 'local_bar';
    if (icon == Icons.local_car_wash) return 'local_car_wash';
    if (icon == Icons.local_convenience_store) return 'local_convenience_store';
    if (icon == Icons.local_drink) return 'local_drink';
    if (icon == Icons.local_florist) return 'local_florist';
    if (icon == Icons.local_laundry_service) return 'local_laundry_service';
    if (icon == Icons.local_library) return 'local_library';
    if (icon == Icons.local_mall) return 'local_mall';
    if (icon == Icons.local_movies) return 'local_movies';
    if (icon == Icons.local_offer) return 'local_offer';
    if (icon == Icons.local_pizza) return 'local_pizza';
    if (icon == Icons.local_play) return 'local_play';
    if (icon == Icons.local_printshop) return 'local_printshop';
    if (icon == Icons.local_see) return 'local_see';
    if (icon == Icons.shopping_cart) return 'shopping_cart';
    if (icon == Icons.theater_comedy) return 'theater_comedy';
    if (icon == Icons.local_activity) return 'local_activity';
    
    return 'place'; // Icône par défaut
  }
}
