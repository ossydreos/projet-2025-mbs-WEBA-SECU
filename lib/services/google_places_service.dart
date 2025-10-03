import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place_suggestion.dart';
import '../utils/constants_optimizer.dart';
import '../utils/logging_service.dart';
import '../utils/ios_optimized_cache.dart';

/// Service centralisé pour toutes les opérations Google Places API
/// Évite les patterns répétés dans 20+ fichiers
class GooglePlacesService {
  static GooglePlacesService? _instance;
  GooglePlacesService._internal();

  static GooglePlacesService get instance {
    _instance ??= GooglePlacesService._internal();
    return _instance!;
  }

  /// Récupère les clés API selon la plateforme
  String get _apiKey {
    return ConstantsOptimizer.googlePlacesWebKey.isNotEmpty
        ? ConstantsOptimizer.googlePlacesWebKey
        : (Platform.isIOS
              ? ConstantsOptimizer.googleMapsApiKeyIOS
              : ConstantsOptimizer.googleMapsApiKeyAndroid);
  }

  /// Recherche autocomplete avec suggestion et cache optimisé iOS
  Future<List<PlaceSuggestion>> fetchSuggestions(String query) async {
    // Vérification du cache d'abord (optimisé pour iOS)
    final cache = IOSOptimizedCache.instance;
    final cachedSuggestions = await cache.getPlaceSuggestions(query);

    if (cachedSuggestions != null) {
      LoggingService.info('Suggestions récupérées du cache iOS: $query');
      return cachedSuggestions
          .map(
            (s) => PlaceSuggestion(
              displayName: s['displayName'] ?? '',
              shortName: s['shortName'] ?? '',
              address: s['address'] ?? '',
              coordinates: s['coordinates'] != null
                  ? LatLng(
                      (s['coordinates']['lat'] as num).toDouble(),
                      (s['coordinates']['lng'] as num).toDouble(),
                    )
                  : null,
              icon: Icons.location_on,
              distance: s['distance'] ?? '',
              placeId: s['placeId'],
            ),
          )
          .toList();
    }

    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.autocompleteApiUrl}'
        '?input=${Uri.encodeComponent(query)}'
        '&sessiontoken=${DateTime.now().microsecondsSinceEpoch}'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString();

        if (status == 'OK') {
          final preds = (data['predictions'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

          final suggestions = preds
              .map((p) => PlaceSuggestion.fromPlaces(p))
              .toList();

          final sortedSuggestions = _sortSuggestionsByPriority(suggestions);

          // Cache les résultats (optimisé pour iOS)
          await cache.setPlaceSuggestions(
            query,
            sortedSuggestions
                .map(
                  (s) => {
                    'displayName': s.displayName,
                    'shortName': s.shortName,
                    'address': s.address,
                    'coordinates': s.coordinates != null
                        ? {
                            'lat': s.coordinates!.latitude,
                            'lng': s.coordinates!.longitude,
                          }
                        : null,
                    'distance': s.distance,
                    'placeId': s.placeId,
                  },
                )
                .toList(),
          );

          return sortedSuggestions;
        } else {
          throw Exception(
            'Google Places error: $status - ${data['error_message']}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Places API exception: $e');
    }
  }

  /// Obtient les coordonnées depuis un Place ID avec cache optimisé iOS
  Future<LatLng?> getPlaceCoordinates(String placeId) async {
    // Vérification du cache d'abord (optimisé pour iOS)
    final cache = IOSOptimizedCache.instance;
    final cachedCoords = await cache.getCoordinates(placeId);

    if (cachedCoords != null) {
      LoggingService.info('Coordonnées récupérées du cache iOS: $placeId');
      return LatLng(cachedCoords['lat']!, cachedCoords['lng']!);
    }

    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.placesApiUrl}'
        '?place_id=$placeId'
        '&fields=geometry&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['result'];

        if (result != null && result['geometry'] != null) {
          final location = result['geometry']['location'];
          final coordinates = LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );

          // Cache les coordonnées (optimisé pour iOS)
          await cache.setCoordinates(placeId, {
            'lat': coordinates.latitude,
            'lng': coordinates.longitude,
          });

          return coordinates;
        }
      }

      return null;
    } catch (e) {
      LoggingService.info('Erreur récupération coordonnées: $e');
      return null;
    }
  }

  /// Géocodage inverse d'une adresse
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.geocodingApiUrl}'
        '?address=${Uri.encodeComponent(address)}&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;

        if (results != null && results.isNotEmpty) {
          final location = results.first['geometry']['location'];
          return LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
        }
      }

      return null;
    } catch (e) {
      LoggingService.info('Erreur géocodage: $e');
      return null;
    }
  }

  /// Tri des suggestions selon la priorité géographique
  List<PlaceSuggestion> _sortSuggestionsByPriority(
    List<PlaceSuggestion> suggestions,
  ) {
    suggestions.sort((a, b) {
      final aIsSwiss = _isSwissAddress(a.address);
      final bIsSwiss = _isSwissAddress(b.address);
      final aIsFrench = _isFrenchAddress(a.address);
      final bIsFrench = _isFrenchAddress(b.address);

      // Priorité : Suisse > France > Autres
      if (aIsSwiss && !bIsSwiss) return -1;
      if (!aIsSwiss && bIsSwiss) return 1;
      if (aIsFrench && !bIsFrench && !bIsSwiss) return -1;
      if (!aIsFrench && bIsFrench && !aIsSwiss) return 1;

      return 0;
    });

    return suggestions;
  }

  /// Détermine si une adresse est en Suisse
  bool _isSwissAddress(String address) {
    final lowerAddress = address.toLowerCase();
    return lowerAddress.contains('suisse') ||
        lowerAddress.contains('switzerland') ||
        lowerAddress.contains('genève') ||
        lowerAddress.contains('zurich') ||
        lowerAddress.contains('bern') ||
        lowerAddress.contains('lausanne') ||
        lowerAddress.contains('basel') ||
        lowerAddress.contains('lucerne');
  }

  /// Détermine si une adresse est en France
  bool _isFrenchAddress(String address) {
    final lowerAddress = address.toLowerCase();
    return lowerAddress.contains('france') ||
        lowerAddress.contains('paris') ||
        lowerAddress.contains('lyon') ||
        lowerAddress.contains('marseille') ||
        lowerAddress.contains('toulouse') ||
        lowerAddress.contains('nice');
  }
}
