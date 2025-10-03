import 'package:flutter/material.dart';

/// Mixin pour gérer les états de chargement de façon centralisée
/// Évite la duplication de bool _isLoading partout
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  // Map pour stocker plusieurs états de chargement
  final Map<String, bool> _loadingStates = {};

  /// Vérifie si un état de chargement spécifique est actif
  bool isLoading([String key = 'default']) {
    return _loadingStates[key] ?? false;
  }

  /// Démarre un état de chargement et rebuild
  void setLoading(bool loading, [String key = 'default']) {
    if (mounted) {
      setState(() {
        _loadingStates[key] = loading;
      });
    }
  }

  /// Exécute une opération avec gestion automatique du loading
  Future<R?> executeLoading<R>(
    Future<R> Function() operation, {
    String loadingKey = 'default',
    String? successMessage,
    String? errorPrefix,
  }) async {
    setLoading(true, loadingKey);
    
    try {
      final result = await operation();
      
      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      }
      
      return result;
    } catch (e) {
      final errorMessage = errorPrefix != null 
          ? '$errorPrefix: $e' 
          : 'Erreur: $e';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
      
      return null;
    } finally {
      setLoading(false, loadingKey);
    }
  }

  /// Widget de chargement réutilisable
  Widget buildLoadingIndicator({String key = 'default'}) {
    return Visibility(
      visible: isLoading(key),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Overlay de chargement pour l'écran entier
  Widget buildLoadingOverlay({String key = 'default'}) {
    return Stack(
      children: [
        child,
        if (isLoading(key))
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
