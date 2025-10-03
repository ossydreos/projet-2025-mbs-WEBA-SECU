import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place_suggestion.dart';
import '../utils/constants_optimizer.dart';

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

  /// Recherche autocomplete avec suggestion
  Future<List<PlaceSuggestion>> fetchSuggestions(String query) async {
    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.autocompleteApiUrl}'
        '?input=${Uri.encodeComponent(query)}'
        '&sessiontoken=${DateTime.now().microsecondsSinceEpoch}'
        '&key=$_apiKey'
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
          
          return _sortSuggestionsByPriority(suggestions);
        } else {
          throw Exception('Google Places error: $status - ${data['error_message']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Places API exception: $e');
    }
  }

  /// Obtient les coordonnées depuis un Place ID
  Future<LatLng?> getPlaceCoordinates(String placeId) async {
    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.placesApiUrl}'
        '?place_id=$placeId'
        '&fields=geometry&key=$_apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['result'];
        
        if (result != null && result['geometry'] != null) {
          final location = result['geometry']['location'];
          return LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
        }
      }
      
      return null;
    } catch (e) {    LoggingService.info('Erreur récupération coordonnées: $e');
      return null;
    }
  }

  /// Géocodage inverse d'une adresse
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        '${ConstantsOptimizer.geocodingApiUrl}'
        '?address=${Uri.encodeComponent(address)}&key=$_apiKey'
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
    } catch (e) {    LoggingService.info('Erreur géocodage: $e');
      return null;
    }
  }

  /// Tri des suggestions selon la priorité géographique
  List<PlaceSuggestion> _sortSuggestionsByPriority(List<PlaceSuggestion> suggestions) {
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
