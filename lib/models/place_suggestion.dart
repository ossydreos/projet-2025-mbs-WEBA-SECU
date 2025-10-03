import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Modèle centralisé pour les suggestions de lieux
/// Remplace les classes Suggestion dupliquées dans 3 fichiers
class PlaceSuggestion {
  final String displayName;
  final String shortName;
  final String address;
  final LatLng? coordinates;
  final IconData icon;
  final String distance;
  final String? placeId;

  PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.address,
    required this.coordinates,
    required this.icon,
    required this.distance,
    this.placeId,
  });

  /// Factory constructor par Google Places API
  factory PlaceSuggestion.fromPlaces(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    final shortName = (structured['main_text'] ?? '').toString();
    final secondary = (structured['secondary_text'] ?? '').toString();
    final display = json['description']?.toString() ?? shortName;
    final placeId = json['place_id']?.toString();

    return PlaceSuggestion(
      displayName: display,
      shortName: shortName.isNotEmpty ? shortName : display,
      address: secondary,
      coordinates: null,
      icon: Icons.location_on,
      distance: '',
      placeId: placeId,
    );
  }

  /// Conversion vers l'objet original pour compatibilité
  PlaceSuggestion copyWith({
    String? displayName,
    String? shortName,
    String? address,
    LatLng? coordinates,
    IconData? icon,
    String? distance,
    String? placeId,
  }) {
    return PlaceSuggestion(
      displayName: displayName ?? this.displayName,
      shortName: shortName ?? this.shortName,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      icon: icon ?? this.icon,
      distance: distance ?? this.distance,
      placeId: placeId ?? this.placeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceSuggestion &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          shortName == other.shortName &&
          address == other.address &&
          placeId == other.placeId;

  @override
  int get hashCode =>
      displayName.hashCode ^
      shortName.hashCode ^
      address.hashCode ^
      placeId.hashCode;

  @override
  String toString() {
    return 'PlaceSuggestion{displayName: $displayName, shortName: $shortName, address: $address, placeId: $placeId}';
  }
}
