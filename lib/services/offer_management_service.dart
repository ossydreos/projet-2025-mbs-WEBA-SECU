import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../data/models/custom_offer.dart';
import '../models/place_suggestion.dart';
import 'google_places_service.dart';
import '../utils/constants_optimizer.dart';
import '../utils/price_calculator.dart';
import '../utils/logging_service.dart';

/// Service centralisé pour la gestion des offres personnalisées
/// Extrait la logique métier du fichier monstre custom_offer_creation_screen.dart
class OfferManagementService {
  static OfferManagementService? _instance;
  OfferManagementService._internal();

  static OfferManagementService get instance {
    _instance ??= OfferManagementService._internal();
    return _instance!;
  }

  /// Calcule la distance entre deux points (utilise l'API Directions)
  Future<double?> calculateDistance(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.directionsApiUrl}'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=${ConstantsOptimizer.getGooglePlacesKey()}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final legs = routes.first['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            return (legs.first['distance']['value'] as num).toDouble() /
                1000; // En km
          }
        }
      }

      return null;
    } catch (e) {
      LoggingService.info('Erreur calcul distance: $e');
      return null;
    }
  }

  /// Recherche de lieux avec géocodage
  Future<List<PlaceSuggestion>> searchPlacesWithCoordinates(
    String query,
  ) async {
    try {
      final suggestions = await GooglePlacesService.instance.fetchSuggestions(
        query,
      );

      // Enrichir avec les coordonnées pour chaque suggestion
      final enrichedSuggestions = <PlaceSuggestion>[];

      for (final suggestion in suggestions) {
        LatLng? coordinates;

        if (suggestion.placeId != null) {
          coordinates = await GooglePlacesService.instance.getPlaceCoordinates(
            suggestion.placeId!,
          );
        } else if (suggestion.shortName.isNotEmpty) {
          // Géocoder directement si pas de placeId
          coordinates = await GooglePlacesService.instance.geocodeAddress(
            suggestion.shortName,
          );
        }

        enrichedSuggestions.add(suggestion.copyWith(coordinates: coordinates));
      }

      return enrichedSuggestions;
    } catch (e) {
      LoggingService.info('Erreur recherche lieux: $e');
      return [];
    }
  }

  /// Calcule le prix total d'une offre personnalisée
  OfferPricing calculateOfferPricing({
    required double distanceKm,
    required String vehicleType,
    required DateTime pickupTime,
    required int passengers,
  }) {
    // Prix de base selon la distance
    final basePrice = PriceCalculator.calculateBasePrice(
      distanceKm,
      vehicleType: vehicleType,
    );

    // Appliquer les multiplicateurs (nuit/weekend)
    final adjustedPrice = PriceCalculator.applyTimeMultiplier(
      basePrice,
      pickupTime,
    );

    // Prix final arrondi
    final finalPrice = PriceCalculator.applyBusinessRounding(adjustedPrice);

    // Commission admin
    final adminCommission = PriceCalculator.calculateAdminCommission(
      finalPrice,
    );

    return OfferPricing(
      basePrice: basePrice,
      adjustedPrice: adjustedPrice,
      finalPrice: finalPrice,
      distanceKm: distanceKm,
      adminCommission: adminCommission,
      breakdown: _generatePricingBreakdown(
        basePrice,
        adjustedPrice,
        finalPrice,
        distanceKm,
        vehicleType,
      ),
    );
  }

  /// Génère le breakdown détaillé des prix
  Map<String, dynamic> _generatePricingBreakdown(
    double basePrice,
    double adjustedPrice,
    double finalPrice,
    double distanceKm,
    String vehicleType,
  ) {
    return {
      'vehicle_type': vehicleType,
      'distance_km': distanceKm.toStringAsFixed(1),
      'base_price': '+ ${basePrice.toStringAsFixed(2)} CHF',
      'time_multiplier': adjustedPrice != basePrice
          ? '+ ${(adjustedPrice - basePrice).toStringAsFixed(2)} CHF (nuit/weekend)'
          : 'Aucun supplément',
      'business_rounding': finalPrice != adjustedPrice
          ? '+ ${(finalPrice - adjustedPrice).toStringAsFixed(2)} CHF (arrondi)'
          : 'Aucun arrondi',
      'total': '${finalPrice.toStringAsFixed(2)} CHF',
    };
  }

  /// Valide une offre personnalisée avant création
  ValidationResult validateOffer({
    required LatLng? pickupLocation,
    required LatLng? destinationLocation,
    required DateTime pickupTime,
    required int passengers,
    required String vehicleType,
  }) {
    // Vérifications géographiques
    if (pickupLocation == null || destinationLocation == null) {
      return ValidationResult.failed(
        'Veuillez sélectionner un point de départ et d\'arrivée',
      );
    }

    // Vérifications temporelles
    if (pickupTime.isBefore(DateTime.now())) {
      return ValidationResult.failed('Impossible de réserver dans le passé');
    }

    // Vérifications logiques
    if (passengers < 1 || passengers > 6) {
      return ValidationResult.failed('Nombre de passagers invalide (1-6)');
    }

    if (!['standard', 'eco', 'luxury'].contains(vehicleType.toLowerCase())) {
      return ValidationResult.failed('Type de véhicule invalide');
    }

    return ValidationResult.success();
  }

  /// Estime la durée du trajet
  Future<Duration?> estimateTripDuration(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.directionsApiUrl}'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=${ConstantsOptimizer.getGooglePlacesKey()}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final legs = routes.first['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final durationSeconds = legs.first['duration']['value'] as int;
            return Duration(seconds: durationSeconds);
          }
        }
      }

      return null;
    } catch (e) {
      LoggingService.info('Erreur estimation durée: $e');
      return null;
    }
  }
}

/// Résultat de validation pour les offres
class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult._(this.isValid, this.message);

  factory ValidationResult.success() => ValidationResult._(true, null);
  factory ValidationResult.failed(String message) =>
      ValidationResult._(false, message);
}

/// Structure pour le pricing d'une offre
class OfferPricing {
  final double basePrice;
  final double adjustedPrice;
  final double finalPrice;
  final double distanceKm;
  final double adminCommission;
  final Map<String, dynamic> breakdown;

  OfferPricing({
    required this.basePrice,
    required this.adjustedPrice,
    required this.finalPrice,
    required this.distanceKm,
    required this.adminCommission,
    required this.breakdown,
  });
}
