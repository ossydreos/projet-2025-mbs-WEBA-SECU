import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/constants.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  // Calculer le temps de trajet entre deux points
  static Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Utiliser la clé Places Web qui est configurée pour les requêtes HTTP
      final apiKey = AppConstants.googlePlacesWebKey.isNotEmpty 
          ? AppConstants.googlePlacesWebKey 
          : AppConstants.googleMapsApiKeyAndroid;
          
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
      return null;
    }
  }

  // Fallback : calculer la distance avec la formule de Haversine
  static double _calculateHaversineDistance(LatLng origin, LatLng destination) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final lat1Rad = origin.latitude * (3.14159265359 / 180);
    final lat2Rad = destination.latitude * (3.14159265359 / 180);
    final deltaLatRad = (destination.latitude - origin.latitude) * (3.14159265359 / 180);
    final deltaLngRad = (destination.longitude - origin.longitude) * (3.14159265359 / 180);

    final a = (deltaLatRad / 2) * (deltaLatRad / 2) +
        (deltaLngRad / 2) * (deltaLngRad / 2) * 
        (lat1Rad > 0 ? 1 : -1) * (lat2Rad > 0 ? 1 : -1);
    final c = 2 * (a > 0 ? 1 : -1) * (a.abs() > 1 ? 1 : a.abs());
    
    return earthRadius * c;
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
        
        // Retourner la durée du trajet
        if (durationMinutes < 60) {
          return 'Temps estimé ${durationMinutes} min';
        } else {
          final hours = durationMinutes ~/ 60;
          final minutes = durationMinutes % 60;
          if (minutes == 0) {
            return 'Temps estimé ${hours}h';
          } else {
            return 'Temps estimé ${hours}h ${minutes}min';
          }
        }
      }
      
      // Fallback si l'API ne fonctionne pas
      return 'Temps estimé 15 min';
    } catch (e) {
      return 'Temps estimé 15 min';
    }
  }

  // Obtenir la distance réelle en kilomètres
  static Future<double> getRealDistance({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final directions = await getDirections(
        origin: origin,
        destination: destination,
      );

      if (directions != null) {
        // Convertir les mètres en kilomètres
        return directions['distanceValue'] / 1000.0;
      }
      
      // Fallback avec la formule de Haversine
      return _calculateHaversineDistance(origin, destination);
    } catch (e) {
      return _calculateHaversineDistance(origin, destination);
    }
  }

}
