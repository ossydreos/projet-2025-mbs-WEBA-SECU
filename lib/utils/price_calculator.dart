import 'dart:math';

/// Calculateur de prix centralisé
/// Évite les duplications de logique de pricing
class PriceCalculator {
  
  /// Calcule le prix base selon la distance
  static double calculateBasePrice(double distanceKm, {String vehicleType = 'standard'}) {
    // Tarifs selon le type de véhicule
    double pricePerKm;
    double baseFare;
    
    switch (vehicleType.toLowerCase()) {
      case 'eco':
        pricePerKm = 2.50;
        baseFare = 8.00;
        break;
      case 'luxury':
        pricePerKm = 4.00;
        baseFare = 15.00;
        break;
      case 'standard':
      default:
        pricePerKm = 3.00;
        baseFare = 10.00;
        break;
    }
    
    return baseFare + (distanceKm * pricePerKm);
  }

  /// Applique les tarifs de nuit/weekend
  static double applyTimeMultiplier(double basePrice, DateTime pickupTime) {
    double multiplier = 1.0;
    
    final hour = pickupTime.hour;
    final weekday = pickupTime.weekday;
    
    // Nuit (22h-6h)
    if (hour >= 22 || hour <= 6) {
      multiplier *= 1.3;
    }
    
    // Weekend
    if (weekday == 6 || weekday == 7) { // Samedi ou Dimanche
      multiplier *= 1.2;
    }
    
    // Peak hours (7h-9h et 17h-19h)
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
      multiplier *= 1.15;
    }
    
    return basePrice * multiplier;
  }

  /// Arrondit selon les règles business (au 0,05 CHF près)
  static double applyBusinessRounding(double price) {
    return (price * 20).round() / 20;
  }

  /// Calcule prix total avec taxes
  static double calculateTotalWithTaxes(double basePrice) {
    const double taxRate = 0.077; // TVA Suisse 7.7%
    return basePrice * (1 + taxRate);
  }

  /// Calcule la durée estimée selon la distance
  static Duration estimateDuration(double distanceKm) {
    // Estimation basée sur 25km/h en moyenne dans la ville
    final hours = distanceKm / 25.0;
    return Duration(minutes: (hours * 60).round());
  }

  /// Validation des limites business
  static bool isPriceWithinBusinessLimits(double price, {double maxPrice = 200.0}) {
    return price <= maxPrice && price >= 5.0;
  }

  /// Calcule commission admin (business rules)
  static double calculateAdminCommission(double totalPrice) {
    return totalPrice * 0.15; // 15% commission
  }

  /// Formatage prix pour affichage
  static String formatPrice(double price) {
    return '${price.toStringAsFixed(2)} CHF';
  }
}
