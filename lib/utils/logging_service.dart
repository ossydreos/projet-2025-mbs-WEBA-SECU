import 'package:flutter/foundation.dart';

/// Service de logging centralisé pour l'application
class LoggingService {
  static const String _tag = 'MyMobilityService';

  /// Log d'information
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
    }
  }

  /// Log d'avertissement
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
    }
  }

  /// Log d'erreur
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      if (error != null) {
      }
      if (stackTrace != null) {
      }
    }
  }

  /// Log de debug
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
    }
  }

  /// Log pour le développement uniquement
  static void dev(String message, {String? tag}) {
    if (kDebugMode) {
    }
  }
}
