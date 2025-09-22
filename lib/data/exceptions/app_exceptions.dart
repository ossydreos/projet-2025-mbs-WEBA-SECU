import 'dart:developer' as developer;

/// Classe de base pour toutes les exceptions de l'application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Log l'erreur avec les détails appropriés
  void logError(String serviceName) {
    developer.log(
      message,
      name: serviceName,
      error: originalError ?? this,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    if (code != null) {
      return '$code: $message';
    }
    return message;
  }
}

/// Exception pour les erreurs de validation
class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception pour les erreurs Firestore
class FirestoreException extends AppException {
  const FirestoreException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception pour les erreurs d'authentification
class AuthException extends AppException {
  const AuthException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception pour les erreurs réseau
class NetworkException extends AppException {
  const NetworkException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception pour les erreurs de service
class ServiceException extends AppException {
  const ServiceException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}
