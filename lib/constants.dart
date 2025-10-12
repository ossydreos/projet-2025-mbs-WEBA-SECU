import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase/api_keys_service.dart';

class AppConstants {
  static const sheetRatio = 0.7;
  static final TextStyle defaultTextStyle = GoogleFonts.poppins();

  // Google Maps API keys - Android dans manifeste (obligatoire), autres sécurisées
  static const String googleMapsApiKeyAndroid = 'AIzaSyATiODItwM8vfA-hN1hRNkdE4lLDjGySwc'; // Dans manifeste
  static Future<String> get googleMapsApiKeyIOS async => 
      await ApiKeysService.getGoogleMapsIosKey();
  static Future<String> get googlePlacesWebKey async => 
      await ApiKeysService.getGooglePlacesWebKey();
}
