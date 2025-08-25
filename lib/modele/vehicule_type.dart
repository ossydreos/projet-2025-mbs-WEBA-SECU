import 'package:flutter/material.dart';

class VehiculeType {
  final String name;
  final String price; // ex: "$10" (gardé tel quel pour compatibilité)
  final String capacity; // ex: "4 seats"
  final String luggage; // ex: "487 kg"
  final IconData icon;

  const VehiculeType(
    this.name,
    this.price,
    this.capacity,
    this.luggage,
    this.icon,
  );
}
