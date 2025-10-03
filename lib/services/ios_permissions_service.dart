import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/ios_ui_adapter.dart';

/// Service de gestion des permissions optimisé pour iOS
/// Gère les spécificités des permissions iOS de manière élégante
class IOSPermissionsService {
  static IOSPermissionsService? _instance;
  IOSPermissionsService._internal();

  static IOSPermissionsService get instance {
    _instance ??= IOSPermissionsService._internal();
    return _instance!;
  }

  /// Vérifie et demande les permissions de localisation avec gestion iOS
  Future<bool> requestLocationPermissions() async {
    if (!Platform.isIOS) {
      // Sur Android, utiliser la logique standard
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }

    // Gestion spécifique iOS
    PermissionStatus status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Première demande
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        return true;
      }
    }

    if (status.isPermanentlyDenied) {
      // L'utilisateur a refusé définitivement, ouvrir les paramètres
      await _showIOSPermissionDialog(
        title: 'Localisation requise',
        message:
            'Pour utiliser toutes les fonctionnalités de cette app, veuillez autoriser l\'accès à la localisation dans les paramètres iOS.',
        onSettingsPressed: () => openAppSettings(),
      );
      return false;
    }

    return status.isGranted;
  }

  /// Demande les permissions de localisation en arrière-plan (iOS spécifique)
  Future<bool> requestBackgroundLocationPermission() async {
    if (!Platform.isIOS) {
      return await requestLocationPermissions();
    }

    // Vérifier d'abord les permissions de base
    final basicPermission = await requestLocationPermissions();
    if (!basicPermission) return false;

    // Demander la permission toujours/autoriser
    final status = await Permission.locationAlways.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await _showIOSPermissionDialog(
        title: 'Localisation en arrière-plan',
        message:
            'Pour recevoir des notifications de services disponibles même lorsque l\'app n\'est pas ouverte, autorisez "Toujours" dans les paramètres iOS.',
        onSettingsPressed: () => openAppSettings(),
      );
      return false;
    }

    return status.isGranted;
  }

  /// Demande les permissions de notifications avec gestion iOS
  Future<bool> requestNotificationPermissions() async {
    if (!Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    // Gestion spécifique iOS pour les notifications
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await _showIOSPermissionDialog(
        title: 'Notifications importantes',
        message:
            'Pour recevoir des notifications sur les nouvelles offres et mises à jour, veuillez autoriser les notifications dans les paramètres iOS.',
        onSettingsPressed: () => openAppSettings(),
      );
      return false;
    }

    return status.isGranted;
  }

  /// Demande l'accès aux contacts (si nécessaire)
  Future<bool> requestContactsPermission() async {
    if (!Platform.isIOS) {
      final status = await Permission.contacts.request();
      return status.isGranted;
    }

    final status = await Permission.contacts.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await _showIOSPermissionDialog(
        title: 'Accès aux contacts',
        message:
            'Pour partager facilement des trajets avec vos contacts, autorisez l\'accès aux contacts dans les paramètres iOS.',
        onSettingsPressed: () => openAppSettings(),
      );
      return false;
    }

    return status.isGranted;
  }

  /// Affiche un dialogue iOS élégant pour les permissions refusées
  Future<void> _showIOSPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onSettingsPressed,
  }) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final iosAdapter = IOSUIAdapter.instance;

    await iosAdapter.showAdaptiveAlert(
      context: context,
      title: title,
      message: message,
      confirmText: 'Ouvrir les paramètres',
      cancelText: 'Plus tard',
      onConfirm: onSettingsPressed,
    );
  }

  /// Vérifie si les services de localisation sont activés
  Future<bool> isLocationServicesEnabled() async {
    if (!Platform.isIOS) {
      return await Permission.location.serviceStatus.isEnabled;
    }

    // Sur iOS, vérifier spécifiquement les services de localisation
    return await Permission.location.serviceStatus.isEnabled;
  }

  /// Affiche un dialogue si les services de localisation sont désactivés
  Future<bool> handleDisabledLocationServices() async {
    final isEnabled = await isLocationServicesEnabled();
    if (isEnabled) return true;

    final context = navigatorKey.currentContext;
    if (context == null) return false;

    final iosAdapter = IOSUIAdapter.instance;

    await iosAdapter.showAdaptiveAlert(
      context: context,
      title: 'Localisation désactivée',
      message:
          'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres iOS pour utiliser cette fonctionnalité.',
      confirmText: 'Ouvrir les paramètres',
      cancelText: 'Annuler',
      onConfirm: () async {
        await openAppSettings();
      },
    );

    return false;
  }

  /// Gestionnaire centralisé des permissions pour l'initialisation de l'app
  Future<Map<String, bool>> initializePermissions() async {
    final permissions = <String, bool>{};

    // Localisation de base
    permissions['location'] = await requestLocationPermissions();

    // Localisation en arrière-plan (si la localisation de base est accordée)
    if (permissions['location'] == true) {
      permissions['background_location'] =
          await requestBackgroundLocationPermission();
    } else {
      permissions['background_location'] = false;
    }

    // Notifications
    permissions['notifications'] = await requestNotificationPermissions();

    // Contacts (optionnel)
    permissions['contacts'] = await requestContactsPermission();

    return permissions;
  }

  /// Vérifie le statut d'une permission spécifique
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  /// Force la demande d'une permission spécifique
  Future<bool> requestSpecificPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  /// Ouvre les paramètres iOS avec une animation élégante
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Gestionnaire d'erreurs pour les permissions iOS
  String getPermissionErrorMessage(Permission permission) {
    switch (permission) {
      case Permission.location:
      case Permission.locationAlways:
      case Permission.locationWhenInUse:
        return 'L\'accès à la localisation est nécessaire pour calculer les itinéraires et trouver les services disponibles près de chez vous.';
      case Permission.notification:
        return 'Les notifications vous permettent de recevoir des alertes sur les nouvelles offres et mises à jour importantes.';
      case Permission.contacts:
        return 'L\'accès aux contacts facilite le partage de trajets avec vos amis et contacts de confiance.';
      default:
        return 'Cette permission est nécessaire pour le bon fonctionnement de l\'application.';
    }
  }
}

/// Extension pour faciliter l'utilisation
extension IOSPermissionsExtension on Permission {
  String get iosDescription {
    return IOSPermissionsService.instance.getPermissionErrorMessage(this);
  }
}
