import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/generated/app_localizations.dart';

enum VehicleCategory {
  luxe,
  van,
  economique,
}

// Extension pour obtenir la catégorie localisée
extension VehicleCategoryExtension on VehicleCategory {
  String getLocalizedCategory(context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case VehicleCategory.luxe:
        return localizations.vehicleCategoryLuxe;
      case VehicleCategory.van:
        return localizations.vehicleCategoryVan;
      case VehicleCategory.economique:
        return localizations.vehicleCategoryEconomique;
    }
  }
  
  // Version legacy pour compatibilité
  String get categoryInFrench {
    switch (this) {
      case VehicleCategory.luxe:
        return 'Luxe';
      case VehicleCategory.van:
        return 'Van';
      case VehicleCategory.economique:
        return 'Économique';
    }
  }
}

class VehiculeType {
  final String id;
  final String name;
  final VehicleCategory category;
  final double pricePerKm; // Prix par kilomètre
  final int maxPassengers; // Nombre maximum de passagers
  final int maxLuggage; // Nombre maximum de bagages
  final String description; // Description du véhicule
  final String imageUrl; // URL de l'image du véhicule
  final IconData icon; // Icône du véhicule
  final bool isActive; // Si le véhicule est disponible
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VehiculeType({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerKm,
    required this.maxPassengers,
    required this.maxLuggage,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory avec validation
  factory VehiculeType.create({
    required String id,
    required String name,
    required VehicleCategory category,
    required double pricePerKm,
    required int maxPassengers,
    required int maxLuggage,
    required String description,
    required String imageUrl,
    required IconData icon,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    _validateVehicleData(
      name: name,
      pricePerKm: pricePerKm,
      maxPassengers: maxPassengers,
      maxLuggage: maxLuggage,
      description: description,
    );

    return VehiculeType(
      id: id,
      name: name,
      category: category,
      pricePerKm: pricePerKm,
      maxPassengers: maxPassengers,
      maxLuggage: maxLuggage,
      description: description,
      imageUrl: imageUrl,
      icon: icon,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Validation des données du véhicule
  static void _validateVehicleData({
    required String name,
    required double pricePerKm,
    required int maxPassengers,
    required int maxLuggage,
    required String description,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Le nom du véhicule ne peut pas être vide');
    }
    if (pricePerKm <= 0) {
      throw ArgumentError('Le prix par km doit être positif: $pricePerKm');
    }
    if (maxPassengers <= 0 || maxPassengers > 50) {
      throw ArgumentError('Nombre de passagers invalide: $maxPassengers');
    }
    if (maxLuggage < 0 || maxLuggage > 20) {
      throw ArgumentError('Nombre de bagages invalide: $maxLuggage');
    }
    if (description.isEmpty) {
      throw ArgumentError('La description ne peut pas être vide');
    }
  }

  // Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'pricePerKm': pricePerKm,
      'maxPassengers': maxPassengers,
      'maxLuggage': maxLuggage,
      'description': description,
      'imageUrl': imageUrl,
      'icon': icon.codePoint,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Créer depuis un document Firebase
  factory VehiculeType.fromMap(Map<String, dynamic> map) {
    return VehiculeType(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: VehicleCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => VehicleCategory.economique,
      ),
      pricePerKm: (map['pricePerKm'] ?? 0.0).toDouble(),
      maxPassengers: map['maxPassengers'] ?? 4,
      maxLuggage: map['maxLuggage'] ?? 2,
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      icon: Icons.directions_car, // Utiliser une icône constante pour éviter l'erreur de build
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Copier avec modifications
  VehiculeType copyWith({
    String? id,
    String? name,
    VehicleCategory? category,
    double? pricePerKm,
    int? maxPassengers,
    int? maxLuggage,
    String? description,
    String? imageUrl,
    IconData? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiculeType(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      maxLuggage: maxLuggage ?? this.maxLuggage,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Propriétés calculées pour l'affichage
  String get priceDisplay => '${pricePerKm.toStringAsFixed(2)} CHF/km';
  String get capacityDisplay => '$maxPassengers passagers';
  String get luggageDisplay => '$maxLuggage bagages';
  
}
