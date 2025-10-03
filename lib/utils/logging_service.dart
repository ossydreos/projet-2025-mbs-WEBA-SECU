import 'package:flutter/foundation.dart';

/// Service de logging centralisé pour l'application
class LoggingService {
  static const String _tag = 'MyMobilityService';

  /// Log d'information
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('INFO ${_tag}${tag != null ? '[$tag]' : ''}: $message');
    }
  }

  /// Log d'avertissement
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('WARNING ${_tag}${tag != null ? '[$tag]' : ''}: $message');
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
      print('ERROR ${_tag}${tag != null ? '[$tag]' : ''}: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Log de debug
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('DEBUG ${_tag}${tag != null ? '[$tag]' : ''}: $message');
    }
  }

  /// Log pour le développement uniquement
  static void dev(String message, {String? tag}) {
    if (kDebugMode) {
      print('DEV ${_tag}${tag != null ? '[$tag]' : ''}: $message');
    }
  }
}
