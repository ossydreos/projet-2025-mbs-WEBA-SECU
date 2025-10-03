/// Validateurs métier centralisés
/// Évite les duplications de logique business
class BusinessValidators {
  
  /// Validation email (business rules)
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult.failed('Email requis');
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.failed('Format email invalide');
    }
    
    return ValidationResult.success();
  }

  /// Validation téléphone (business rules) 
  static ValidationResult validatePhone(String phone, {String countryCode = '+41'}) {
    if (phone.isEmpty) {
      return ValidationResult.failed('Numéro requis');
    }
    
    // Enlever tous les espaces et caractères spéciaux
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Suisse: doit commencer par 7 ou 9, avoir 9 chiffres total
    if (countryCode == '+41') {
      if (!cleanPhone.startsWith('7') && !cleanPhone.startsWith('9')) {
        return ValidationResult.failed('Numéro Suisse doit débuter par 7 ou 9');
      }
      if (cleanPhone.length != 9) {
        return ValidationResult.failed('Numéro Suisse doit contenir 9 chiffres');
      }
    }
    
    // Validation chiffres seulement
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return ValidationResult.failed('Numéro doit contenir uniquement des chiffres');
    }
    
    return ValidationResult.success();
  }

  /// Validation prix (business rules)
  static ValidationResult validatePrice(double price, {double minPrice = 5.0, double maxPrice = 200.0}) {
    if (price <= 0) {
      return ValidationResult.failed('Prix doit être positif');
    }
    
    if (price < minPrice) {
      return ValidationResult.failed('Prix minimum: ${minPrice.toStringAsFixed(2)} CHF');
    }
    
    if (price > maxPrice) {
      return ValidationResult.failed('Prix maximum: ${maxPrice.toStringAsFixed(2)} CHF');
    }
    
    return ValidationResult.success();
  }

  /// Validation date réservation (business rules)
  static ValidationResult validateReservationDate(DateTime dateTime) {
    final now = DateTime.now();
    final reservationDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, 
                                         dateTime.hour, dateTime.minute);
    
    // Pas dans le passé
    if (reservationDateTime.isBefore(now)) {
      return ValidationResult.failed('Impossible de réserver dans le passé');
    }
    
    // Pas plus de 30 jours à l'avance
    final maxDate = now.add(Duration(days: 30));
    if (reservationDateTime.isAfter(maxDate)) {
      return ValidationResult.failed('Réservation limitée à 30 jours maximum');
    }
    
    // Pas le dimanche (business rules)
    if (reservationDateTime.weekday == 7) {
      return ValidationResult.failed('Pas de service le dimanche');
    }
    
    return ValidationResult.success();
  }

  /// Validation mot de passe (business rules)
  static ValidationResult validatePassword(String password) {
    if (password.length < 8) {
      return ValidationResult.failed('Minimum 8 caractères');
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return ValidationResult.failed('Au moins une majuscule');
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return ValidationResult.failed('Au moins une minuscule');
    }
    
    if (!RegExp(r'\d').hasMatch(password)) {
      return ValidationResult.failed('Au moins un chiffre');
    }
    
    return ValidationResult.success();
  }
}

class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult._(this.isValid, this.message);

  factory ValidationResult.success() => ValidationResult._(true, null);
  factory ValidationResult.failed(String message) => ValidationResult._(false, message);
}
