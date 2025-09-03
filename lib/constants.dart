import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  static const sheetRatio = 0.7;
  static final TextStyle defaultTextStyle = GoogleFonts.poppins();

  // Google Maps / Places API keys (Android & iOS)
  static const String googleMapsApiKeyAndroid = 'AIzaSyATiODItwM8vfA-hN1hRNkdE4lLDjGySwc';
  static const String googleMapsApiKeyIOS = 'AIzaSyAYhn4l640vzEvk1gC1BtfoG--5SMFcZoI';
  // Clé REST (Places Web Service) — à créer avec restriction "Aucune" et API limitée à Places
  static const String googlePlacesWebKey = 'AIzaSyBDZ8VvSv9OD7s8m5XnooHAmXNo9Uh6sHw';
}
