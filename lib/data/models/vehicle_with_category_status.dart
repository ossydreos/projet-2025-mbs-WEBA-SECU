import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';
import 'package:my_mobility_services/data/models/vehicle_category.dart';

class VehicleWithCategoryStatus {
  final VehiculeType vehicle;
  final bool isCategoryActive;
  final VehicleCategoryModel? categoryInfo;

  const VehicleWithCategoryStatus({
    required this.vehicle,
    required this.isCategoryActive,
    this.categoryInfo,
  });

  // Propriétés déléguées pour faciliter l'utilisation
  String get id => vehicle.id;
  String get name => vehicle.name;
  VehicleCategory get category => vehicle.category;
  double get pricePerKm => vehicle.pricePerKm;
  int get maxPassengers => vehicle.maxPassengers;
  int get maxLuggage => vehicle.maxLuggage;
  String get description => vehicle.description;
  String get imageUrl => vehicle.imageUrl;
  bool get isActive => vehicle.isActive;
  DateTime get createdAt => vehicle.createdAt;
  DateTime? get updatedAt => vehicle.updatedAt;
  String get priceDisplay => vehicle.priceDisplay;
  String get capacityDisplay => vehicle.capacityDisplay;
  String get luggageDisplay => vehicle.luggageDisplay;
  IconData get icon => vehicle.icon;

  // Propriétés calculées
  bool get isSelectable => isActive && isCategoryActive;
  String get statusText => isCategoryActive ? 'Disponible' : 'Indisponible';
  String get categoryDisplayName => categoryInfo?.displayName ?? category.categoryInFrench;
  double get categoryPricePerKm => categoryInfo?.pricePerKm ?? pricePerKm;
}
