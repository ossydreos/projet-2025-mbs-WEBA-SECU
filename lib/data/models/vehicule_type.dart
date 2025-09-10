import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleCategory {
  luxe,
  van,
  economique,
}

// Extension pour obtenir la catégorie en français
extension VehicleCategoryExtension on VehicleCategory {
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
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

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
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Propriétés calculées pour l'affichage
  String get priceDisplay => '${pricePerKm.toStringAsFixed(2)} €/km';
  String get capacityDisplay => '$maxPassengers passagers';
  String get luggageDisplay => '$maxLuggage bagages';
  
  // Icône basée sur la catégorie
  IconData get icon {
    switch (category) {
      case VehicleCategory.luxe:
        return Icons.directions_car;
      case VehicleCategory.van:
        return Icons.airport_shuttle;
      case VehicleCategory.economique:
        return Icons.directions_car_outlined;
    }
  }
}
