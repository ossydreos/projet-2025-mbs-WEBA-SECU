/// Utilitaire pour optimiser et centraliser toutes les constantes
/// Évite les duplications de clés API et config dans tous les fichiers
class ConstantsOptimizer {
  // Api Keys centralisées - sécurisées
  static const String googleMapsApiKeyAndroid = 'AIzaSyATiODItwM8vfA-hN1hRNkdE4lLDjGySwc';
  static const String googleMapsApiKeyIOS = 'AIzaSyAYhn4l640vzEvk1gC1BtfoG--5SMFcZoI';
  static const String googlePlacesWebKey = 'AIzaSyBDZ8VvSv9OD7s8m5XnooHAmXNo9Uh6sHw';

  // Stripe Keys - centralisées depuis payment_service.dart
  static const String stripePublishableKey = 'pk_test_51SA4Pk0xP2bV4rW1o0e3BSzzRNOICsoXLfA2hexPWAaRvNYxYGpM9EXZeOibyR0NMhAeMJoDR9XsM8NVBCbqWxpt00Vr2CovbL';
  static const String stripeSecretKey = 'sk_test_51SA4Pk0xP2bV4rW12MnpPYIjYeNTOJCYIES1TramydQGjEtqw0uUnYYJBwWjAIyVAOjK2VKsLEzva0kTIWIg9svj00j2ERKneZ';

  // Firebase Collections centralisées
  static const String reservationCollection = 'reservations';
  static const String usersCollection = 'users';
  static const String favoriteTripsCollection = 'favorite_trips';
  static const String customOffersCollection = 'custom_offers';
  static const String notificationsCollection = 'notifications';
  static const String promoCodesCollection = 'promo_codes';
  static const String supportThreadsCollection = 'support_threads';
  static const String messagesSubcollection = 'messages';

  // URLs centralisées
  static const String fcmV1Url = 'https://fcm.googleapis.com/v1/projects/my-mobility-services/messages:send';
  static const String directionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String geocodingApiUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String placesApiUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String autocompleteApiUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  // Admin IDs
  static const String adminUserId = 'XIi0afPTqRZaGwrh6oBkArLCd813';

  // Configuration app
  static const double sheetRatio = 0.7;
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const Duration notificationSoundInterval = Duration(seconds: 3);

  /// Méthode utilitaire pour obtenir la bonne clé selon la plateforme
  static String getGooglePlacesKey() {
    return googlePlacesWebKey.isNotEmpty 
        ? googlePlacesWebKey 
        : googleMapsApiKeyAndroid;
  }

  /// Méthode utilitaire pour les clés Stripe (dev seulement !)
  static Map<String, String> getStripeKeys() {
    return {
      'publishable': stripePublishableKey,
      'secret': stripeSecretKey,
    };
  }

  /// Méthode utilitaire pour valider une collection
  static bool isValidCollection(String collection) {
    return collection.isNotEmpty && !collection.contains(' ');
  }
}
