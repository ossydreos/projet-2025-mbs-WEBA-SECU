import 'package:flutter/material.dart';

/// Gestionnaire centralisé des erreurs et feedback utilisateur
/// Remplace les patterns try-catch/setState/snackbar dupliqués
class ErrorHandler {
  /// Exécute une opération async avec gestion automatique d'erreur
  static Future<T?> executeWithErrorHandling<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? successMessage,
    String? errorPrefix,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final result = await operation();
      
      if (successMessage != null) {
        showSnackBar(
          context,
          successMessage,
          type: SnackBarType.success,
        );
      }
      
      onSuccess?.call();
      return result;
    } catch (e) {
      final errorMessage = errorPrefix != null 
          ? '$errorPrefix: $e' 
          : 'Erreur: $e';
      
      showSnackBar(
        context,
        errorMessage,
        type: SnackBarType.error,
      );
      
      onError?.call();
      return null;
    }
  }

  /// Affiche une snackbar avec type prédéfini
  static void showSnackBar(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _getBackgroundColor(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Color _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Colors.green;
      case SnackBarType.error:
        return Colors.red;
      case SnackBarType.warning:
        return Colors.orange;
      case SnackBarType.info:
        return Colors.blue;
    }
  }
}

enum SnackBarType { success, error, warning, info }
