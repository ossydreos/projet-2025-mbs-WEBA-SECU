import 'package:flutter/material.dart';
import '../constants.dart';
import '../firebase/api_keys_service.dart';

class MapsInitializationService {
  static bool _isInitialized = false;
  static String? _cachedApiKey;

  /// Initialise Google Maps avec la clé sécurisée
  static Future<void> initializeMaps() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔐 Récupération de la clé Google Maps sécurisée...');
      
      // Récupérer la clé depuis Firebase Functions
      _cachedApiKey = await ApiKeysService.getGoogleMapsAndroidKey();
      
      debugPrint('✅ Clé Google Maps récupérée: ${_cachedApiKey!.substring(0, 20)}...');
      
      // Google Maps Flutter n'a pas besoin d'initialisation explicite
      // La clé est utilisée automatiquement quand on crée les widgets
      
      _isInitialized = true;
      debugPrint('✅ Google Maps prêt avec clé sécurisée !');
      
    } catch (e) {
      debugPrint('❌ Erreur récupération clé Google Maps: $e');
      rethrow;
    }
  }

  /// Récupère la clé API (depuis le cache ou Firebase)
  static Future<String> getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey!;
    
    return await ApiKeysService.getGoogleMapsAndroidKey();
  }

  /// Vérifie si Maps est initialisé
  static bool get isInitialized => _isInitialized;
}
