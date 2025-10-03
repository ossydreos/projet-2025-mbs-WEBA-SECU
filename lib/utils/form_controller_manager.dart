import 'package:flutter/material.dart';

/// Gestionnaire centralisé des TextEditingController
/// Évite la duplication de controller.dispose() partout
class FormControllerManager {
  final Map<String, TextEditingController> _controllers = {};

  /// Créer ou récupérer un controller par nom
  TextEditingController getController(String name) {
    _controllers[name] ??= TextEditingController();
    return _controllers[name]!;
  }

  /// Définir le texte d'un controller
  void setText(String name, String text) {
    getController(name).text = text;
  }

  /// Récupérer le texte d'un controller
  String getText(String name) {
    return getController(name).text;
  }

  /// Clear un controller spécifique
  void clear(String name) {
    getController(name).clear();
  }

  /// Clear tous les controllers
  void clearAll() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  /// Valider si un controller est vide
  bool isEmpty(String name) {
    return getText(name).trim().isEmpty;
  }

  /// Valider plusieurs controllers (true si tous remplis)
  bool validateFields(List<String> requiredFields) {
    return !requiredFields.any((field) => isEmpty(field));
  }

  /// Disposer tous les controllers
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  /// Getter pour accéder simplement aux controllers dans les widgets
  Map<String, TextEditingController> get all => _controllers;
}
