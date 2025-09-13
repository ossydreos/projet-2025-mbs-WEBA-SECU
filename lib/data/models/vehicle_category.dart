import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleCategoryModel {
  final String id;
  final String name;
  final String displayName; // Nom affiché en français
  final double pricePerKm; // Prix par kilomètre pour cette catégorie
  final bool isActive; // Si la catégorie est active/disponible
  final String description; // Description de la catégorie
  final IconData icon; // Icône de la catégorie
  final int maxPassengers; // Nombre maximum de passagers
  final int maxLuggage; // Nombre maximum de bagages
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VehicleCategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.pricePerKm,
    required this.isActive,
    required this.description,
    required this.icon,
    required this.maxPassengers,
    required this.maxLuggage,
    required this.createdAt,
    this.updatedAt,
  });

  // Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'pricePerKm': pricePerKm,
      'isActive': isActive,
      'description': description,
      'iconCodePoint': icon.codePoint, // Stocker le code point de l'icône
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'maxPassengers': maxPassengers,
      'maxLuggage': maxLuggage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Créer depuis un document Firebase
  factory VehicleCategoryModel.fromMap(Map<String, dynamic> map) {
    return VehicleCategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? '',
      pricePerKm: (map['pricePerKm'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
      description: map['description'] ?? '',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.directions_car_outlined.codePoint,
        fontFamily: map['iconFontFamily'] ?? Icons.directions_car_outlined.fontFamily,
        fontPackage: map['iconFontPackage'] ?? Icons.directions_car_outlined.fontPackage,
      ),
      maxPassengers: map['maxPassengers'] ?? 4,
      maxLuggage: map['maxLuggage'] ?? 2,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Copier avec modifications
  VehicleCategoryModel copyWith({
    String? id,
    String? name,
    String? displayName,
    double? pricePerKm,
    bool? isActive,
    String? description,
    IconData? icon,
    int? maxPassengers,
    int? maxLuggage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      maxLuggage: maxLuggage ?? this.maxLuggage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Propriétés calculées pour l'affichage
  String get priceDisplay => '${pricePerKm.toStringAsFixed(2)} €/km';
  
  // Affichage de la capacité
  String get capacityDisplay => '$maxPassengers passager${maxPassengers > 1 ? 's' : ''}';
  
  // Affichage des bagages
  String get luggageDisplay => '$maxLuggage bagage${maxLuggage > 1 ? 's' : ''}';
  
  // Couleur basée sur l'état actif/inactif
  Color get statusColor => isActive ? Colors.green : Colors.red;
  
  // Texte de statut
  String get statusText => isActive ? 'Active' : 'Inactive';
}
