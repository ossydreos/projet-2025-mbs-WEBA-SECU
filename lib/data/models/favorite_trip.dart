import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Modèle pour les trajets favoris
class FavoriteTrip {
  final String id;
  final String userId;
  final String departureAddress;
  final String arrivalAddress;
  final IconData icon;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final LatLng? departureCoordinates;
  final LatLng? arrivalCoordinates;

  FavoriteTrip({
    required this.id,
    required this.userId,
    required this.departureAddress,
    required this.arrivalAddress,
    required this.icon,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.departureCoordinates,
    this.arrivalCoordinates,
  });

  /// Créer depuis un document Firestore
  factory FavoriteTrip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteTrip(
      id: doc.id,
      userId: data['userId'] ?? '',
      departureAddress: data['departureAddress'] ?? '',
      arrivalAddress: data['arrivalAddress'] ?? '',
      icon: _getIconFromString(data['icon'] ?? 'place'),
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      departureCoordinates: _getLatLngFromData(data['departureCoordinates']),
      arrivalCoordinates: _getLatLngFromData(data['arrivalCoordinates']),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'departureAddress': departureAddress,
      'arrivalAddress': arrivalAddress,
      'icon': _getStringFromIcon(icon),
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'departureCoordinates': _getDataFromLatLng(departureCoordinates),
      'arrivalCoordinates': _getDataFromLatLng(arrivalCoordinates),
    };
  }

  /// Copier avec modifications
  FavoriteTrip copyWith({
    String? id,
    String? userId,
    String? departureAddress,
    String? arrivalAddress,
    IconData? icon,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    LatLng? departureCoordinates,
    LatLng? arrivalCoordinates,
  }) {
    return FavoriteTrip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      departureAddress: departureAddress ?? this.departureAddress,
      arrivalAddress: arrivalAddress ?? this.arrivalAddress,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departureCoordinates: departureCoordinates ?? this.departureCoordinates,
      arrivalCoordinates: arrivalCoordinates ?? this.arrivalCoordinates,
    );
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

  /// Convertir String en IconData depuis Firestore
  static IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'place':
        return Icons.place;
      case 'location_on':
        return Icons.location_on;
      case 'location_city':
        return Icons.location_city;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'local_restaurant':
        return Icons.local_restaurant;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'local_parking':
        return Icons.local_parking;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'local_post_office':
        return Icons.local_post_office;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'local_airport':
        return Icons.local_airport;
      case 'local_atm':
        return Icons.local_atm;
      case 'local_bar':
        return Icons.local_bar;
      case 'local_car_wash':
        return Icons.local_car_wash;
      case 'local_convenience_store':
        return Icons.local_convenience_store;
      case 'local_drink':
        return Icons.local_drink;
      case 'local_florist':
        return Icons.local_florist;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'local_library':
        return Icons.local_library;
      case 'local_mall':
        return Icons.local_mall;
      case 'local_movies':
        return Icons.local_movies;
      case 'local_offer':
        return Icons.local_offer;
      case 'local_pizza':
        return Icons.local_pizza;
      case 'local_play':
        return Icons.local_play;
      case 'local_printshop':
        return Icons.local_printshop;
      case 'local_see':
        return Icons.local_see;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'theater_comedy':
        return Icons.theater_comedy;
      case 'local_activity':
        return Icons.local_activity;
      default:
        return Icons.place; // Icône par défaut
    }
  }

  /// Liste des icônes disponibles pour la sélection
  static List<Map<String, dynamic>> getAvailableIcons() {
    return [
      {'icon': Icons.home, 'name': 'Maison'},
      {'icon': Icons.work, 'name': 'Travail'},
      {'icon': Icons.school, 'name': 'École'},
      {'icon': Icons.place, 'name': 'Lieu'},
      {'icon': Icons.location_on, 'name': 'Position'},
      {'icon': Icons.location_city, 'name': 'Ville'},
      {'icon': Icons.local_hospital, 'name': 'Hôpital'},
      {'icon': Icons.local_grocery_store, 'name': 'Épicerie'},
      {'icon': Icons.local_restaurant, 'name': 'Restaurant'},
      {'icon': Icons.local_cafe, 'name': 'Café'},
      {'icon': Icons.local_gas_station, 'name': 'Station-service'},
      {'icon': Icons.local_parking, 'name': 'Parking'},
      {'icon': Icons.local_pharmacy, 'name': 'Pharmacie'},
      {'icon': Icons.local_post_office, 'name': 'Poste'},
      {'icon': Icons.local_shipping, 'name': 'Livraison'},
      {'icon': Icons.local_taxi, 'name': 'Taxi'},
      {'icon': Icons.local_airport, 'name': 'Aéroport'},
      {'icon': Icons.local_atm, 'name': 'Distributeur'},
      {'icon': Icons.local_bar, 'name': 'Bar'},
      {'icon': Icons.local_library, 'name': 'Bibliothèque'},
      {'icon': Icons.local_mall, 'name': 'Centre commercial'},
      {'icon': Icons.local_movies, 'name': 'Cinéma'},
      {'icon': Icons.local_pizza, 'name': 'Pizzeria'},
      {'icon': Icons.shopping_cart, 'name': 'Shopping'},
      {'icon': Icons.theater_comedy, 'name': 'Théâtre'},
    ];
  }

  /// Convertir LatLng en Map pour Firestore
  static Map<String, dynamic>? _getDataFromLatLng(LatLng? latLng) {
    if (latLng == null) return null;
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    };
  }

  /// Convertir Map en LatLng depuis Firestore
  static LatLng? _getLatLngFromData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'FavoriteTrip(id: $id, name: $name, departure: $departureAddress, arrival: $arrivalAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteTrip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
