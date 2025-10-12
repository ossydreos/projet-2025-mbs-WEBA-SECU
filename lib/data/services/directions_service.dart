import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/constants.dart';
import '../../../l10n/generated/app_localizations.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  // Calculer le temps de trajet entre deux points
  static Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Utiliser la clé Places Web qui est configurée pour les requêtes HTTP
      final apiKey = await AppConstants.googlePlacesWebKey;
          
      final url = Uri.parse('$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$apiKey'
          '&language=fr'
          '&units=metric');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          return {
            'duration': leg['duration']['text'], // Ex: "15 mins"
            'durationValue': leg['duration']['value'], // Ex: 900 (secondes)
            'distance': leg['distance']['text'], // Ex: "5.2 km"
            'distanceValue': leg['distance']['value'], // Ex: 5200 (mètres)
            'polyline': route['overview_polyline']['points'], // Pour le tracé de la route
          };
        }
      }
      
      return null;
    } catch (e) {
      developer.log(
        'Erreur lors de la récupération des directions: $e',
        name: 'DirectionsService',
        error: e,
      );
      return null;
    }
  }


  // Obtenir le temps de trajet formaté
  static Future<String> getEstimatedArrivalTime({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final directions = await getDirections(
        origin: origin,
        destination: destination,
      );

      if (directions != null) {
        final durationMinutes = (directions['durationValue'] / 60).round();
        
        // Retourner la durée du trajet (format international)
        if (durationMinutes < 60) {
          return '${durationMinutes} min';
        } else {
          final hours = durationMinutes ~/ 60;
          final minutes = durationMinutes % 60;
          if (minutes == 0) {
            return '${hours}h';
          } else {
            return '${hours}h ${minutes}min';
          }
        }
      }
      
      // Fallback si l'API ne fonctionne pas
      developer.log(
        'Impossible de récupérer le temps de trajet, utilisation du fallback',
        name: 'DirectionsService',
      );
      return '15 min';
    } catch (e) {
      developer.log(
        'Erreur lors du calcul du temps de trajet: $e',
        name: 'DirectionsService',
        error: e,
      );
      return '15 min';
    }
  }

  // Obtenir le temps de trajet formaté avec localisation (nécessite un BuildContext)
  static Future<String> getLocalizedEstimatedArrivalTime({
    required LatLng origin,
    required LatLng destination,
    required context,
  }) async {
    try {
      final directions = await getDirections(
        origin: origin,
        destination: destination,
      );

      if (directions != null) {
        final durationMinutes = (directions['durationValue'] / 60).round();
        
        // Utiliser le helper de localisation
        final hours = durationMinutes ~/ 60;
        final minutes = durationMinutes % 60;
        if (hours > 0) {
          return '${hours}h ${minutes}min';
        } else {
          return '${minutes}min';
        }
      }
      
      // Fallback localisé
      developer.log(
        'Impossible de récupérer le temps de trajet, utilisation du fallback',
        name: 'DirectionsService',
      );
      return '15min';
    } catch (e) {
      developer.log(
        'Erreur lors du calcul du temps de trajet: $e',
        name: 'DirectionsService',
        error: e,
      );
      return '15min';
    }
  }

  // Obtenir la distance réelle en kilomètres
  static Future<double> getRealDistance({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final directions = await getDirections(
      origin: origin,
      destination: destination,
    );

    if (directions != null) {
      // Convertir les mètres en kilomètres
      return directions['distanceValue'] / 1000.0;
    }
    
    // Pas de fallback - l'API doit fonctionner
    throw Exception('Impossible de calculer la distance - API Google Maps indisponible');
  }

}
