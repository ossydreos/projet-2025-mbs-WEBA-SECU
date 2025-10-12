import 'package:cloud_functions/cloud_functions.dart';

class ApiKeysService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Cache pour éviter les appels répétés
  static String? _mapsAndroidKey;
  static String? _mapsIosKey;
  static String? _placesWebKey;
  static String? _stripePublishableKey;
  static String? _stripeSecretKey;

  /// Récupère la clé Google Maps Android depuis Firebase Functions
  static Future<String> getGoogleMapsAndroidKey() async {
    if (_mapsAndroidKey != null) return _mapsAndroidKey!;
    
    try {
      final result = await _functions.httpsCallable('getApiKeys').call();
      final data = result.data as Map<String, dynamic>;
      _mapsAndroidKey = data['googleMapsAndroidKey'] as String;
      return _mapsAndroidKey!;
    } catch (e) {
      throw Exception('Erreur récupération clé Maps Android: $e');
    }
  }

  /// Récupère la clé Google Maps iOS depuis Firebase Functions
  static Future<String> getGoogleMapsIosKey() async {
    if (_mapsIosKey != null) return _mapsIosKey!;
    
    try {
      final result = await _functions.httpsCallable('getApiKeys').call();
      final data = result.data as Map<String, dynamic>;
      _mapsIosKey = data['googleMapsIosKey'] as String;
      return _mapsIosKey!;
    } catch (e) {
      throw Exception('Erreur récupération clé Maps iOS: $e');
    }
  }

  /// Récupère la clé Google Places Web depuis Firebase Functions
  static Future<String> getGooglePlacesWebKey() async {
    if (_placesWebKey != null) return _placesWebKey!;
    
    try {
      final result = await _functions.httpsCallable('getApiKeys').call();
      final data = result.data as Map<String, dynamic>;
      _placesWebKey = data['googlePlacesWebKey'] as String;
      return _placesWebKey!;
    } catch (e) {
      throw Exception('Erreur récupération clé Places Web: $e');
    }
  }

  /// Récupère la clé publique Stripe depuis Firebase Functions
  static Future<String> getStripePublishableKey() async {
    if (_stripePublishableKey != null) return _stripePublishableKey!;
    
    try {
      final result = await _functions.httpsCallable('getApiKeys').call();
      final data = result.data as Map<String, dynamic>;
      _stripePublishableKey = data['stripePublishableKey'] as String;
      return _stripePublishableKey!;
    } catch (e) {
      throw Exception('Erreur récupération clé publique Stripe: $e');
    }
  }

  /// Récupère la clé secrète Stripe depuis Firebase Functions
  static Future<String> getStripeSecretKey() async {
    if (_stripeSecretKey != null) return _stripeSecretKey!;
    
    try {
      final result = await _functions.httpsCallable('getApiKeys').call();
      final data = result.data as Map<String, dynamic>;
      _stripeSecretKey = data['stripeSecretKey'] as String;
      return _stripeSecretKey!;
    } catch (e) {
      throw Exception('Erreur récupération clé secrète Stripe: $e');
    }
  }

  /// Vide le cache (utile pour les tests ou changement de clés)
  static void clearCache() {
    _mapsAndroidKey = null;
    _mapsIosKey = null;
    _placesWebKey = null;
    _stripePublishableKey = null;
    _stripeSecretKey = null;
  }
}
