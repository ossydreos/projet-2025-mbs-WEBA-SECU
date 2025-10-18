import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Service d'optimisation des assets pour iOS
/// Gère automatiquement les différentes tailles d'icônes et d'images iOS
class IOSAssetOptimizer {
  static IOSAssetOptimizer? _instance;
  IOSAssetOptimizer._internal();

  static IOSAssetOptimizer get instance {
    _instance ??= IOSAssetOptimizer._internal();
    return _instance!;
  }

  /// Tailles d'icônes iOS recommandées
  static const Map<String, int> _iosIconSizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  /// Tailles de splash screen iOS recommandées
  static const Map<String, int> _iosSplashSizes = {
    'LaunchImage-640x960.png': 640,
    'LaunchImage-640x1136.png': 640,
    'LaunchImage-750x1334.png': 750,
    'LaunchImage-1242x2208.png': 1242,
    'LaunchImage-1125x2436.png': 1125,
    'LaunchImage-1536x2048.png': 1536,
    'LaunchImage-1668x2224.png': 1668,
    'LaunchImage-2048x2732.png': 2048,
  };

  /// Récupère l'icône adaptée à la taille d'écran iOS
  String getAdaptiveIcon(double screenWidth, double screenHeight) {
    if (!Platform.isIOS) {
      return 'assets/images/MBG-LogoJauneLime.png'; // Retour par défaut
    }

    // Détermine la taille d'icône appropriée selon les dimensions de l'écran
    final screenSize = screenWidth * screenHeight;

    if (screenSize >= 2048 * 2732) {
      // iPad Pro 12.9"
      return 'assets/images/ios-icons/Icon-App-1024x1024@1x.png';
    } else if (screenSize >= 1668 * 2224) {
      // iPad Pro 11"
      return 'assets/images/ios-icons/Icon-App-83.5x83.5@2x.png';
    } else if (screenSize >= 1536 * 2048) {
      // iPad (9.7", 10.5")
      return 'assets/images/ios-icons/Icon-App-76x76@2x.png';
    } else if (screenHeight >= 812) {
      // iPhone X et plus récents
      return 'assets/images/ios-icons/Icon-App-60x60@3x.png';
    } else if (screenHeight >= 667) {
      // iPhone 6/7/8 Plus
      return 'assets/images/ios-icons/Icon-App-60x60@2x.png';
    } else {
      // iPhone standard et anciens modèles
      return 'assets/images/ios-icons/Icon-App-60x60@2x.png';
    }
  }

  /// Récupère le splash screen adapté à l'appareil iOS
  String getAdaptiveSplashScreen(double screenWidth, double screenHeight) {
    if (!Platform.isIOS) {
      return 'assets/images/MBG-LogoJauneLime.png';
    }

    // Détermine le splash screen approprié selon les dimensions
    final ratio = screenHeight / screenWidth;

    if (ratio >= 2.16) {
      // Très allongé (iPhone X series)
      return 'assets/images/ios-splash/LaunchImage-1125x2436.png';
    } else if (ratio >= 1.77) {
      // Allongé (iPhone 6/7/8 Plus)
      return 'assets/images/ios-splash/LaunchImage-1242x2208.png';
    } else if (ratio >= 1.5) {
      // Standard (iPhone 6/7/8)
      return 'assets/images/ios-splash/LaunchImage-750x1334.png';
    } else {
      // Anciens modèles
      return 'assets/images/ios-splash/LaunchImage-640x1136.png';
    }
  }

  /// Récupère l'image adaptée selon la résolution iOS
  String getAdaptiveImage(String basePath, double devicePixelRatio) {
    if (!Platform.isIOS) {
      return basePath;
    }

    // Détermine l'échelle appropriée pour iOS
    if (devicePixelRatio >= 3.0) {
      return '$basePath@3x.png';
    } else if (devicePixelRatio >= 2.0) {
      return '$basePath@2x.png';
    } else {
      return '$basePath.png';
    }
  }

  /// Précharge les assets critiques pour améliorer les performances iOS
  Future<void> preloadCriticalAssets() async {
    if (!Platform.isIOS) return;

    final criticalAssets = [
      'assets/images/MBG-LogoJauneLime.png',
      'assets/images/ios-icons/Icon-App-60x60@2x.png',
      'assets/images/ios-icons/Icon-App-60x60@3x.png',
    ];

    for (final asset in criticalAssets) {
      try {
        await rootBundle.load(asset);
      } catch (e) {
      }
    }
  }

  /// Génère automatiquement les noms de fichiers iOS pour les icônes
  List<String> generateIOSIconNames() {
    return _iosIconSizes.keys.toList();
  }

  /// Génère automatiquement les noms de fichiers iOS pour les splash screens
  List<String> generateIOSSplashNames() {
    return _iosSplashSizes.keys.toList();
  }

  /// Vérifie si les assets iOS requis sont présents
  Future<bool> validateIOSAssets() async {
    if (!Platform.isIOS) return true;

    final requiredIcons = [
      'Icon-App-20x20@2x.png',
      'Icon-App-29x29@2x.png',
      'Icon-App-40x40@2x.png',
      'Icon-App-60x60@2x.png',
      'Icon-App-76x76@2x.png',
    ];

    for (final icon in requiredIcons) {
      try {
        await rootBundle.load('assets/images/ios-icons/$icon');
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  /// Informations sur l'appareil iOS actuel
  Map<String, dynamic> getIOSDeviceInfo(BoxConstraints constraints) {
    if (!Platform.isIOS) {
      return {'platform': 'android'};
    }

    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    String deviceType;
    if (screenHeight >= 1024) {
      deviceType = screenWidth >= 1024 ? 'iPad Pro' : 'iPad';
    } else if (screenHeight >= 812) {
      deviceType = 'iPhone Pro/Max';
    } else if (screenHeight >= 667) {
      deviceType = 'iPhone Plus';
    } else {
      deviceType = 'iPhone';
    }

    return {
      'platform': 'iOS',
      'deviceType': deviceType,
      'screenSize': '${screenWidth}x$screenHeight',
      'pixelRatio': devicePixelRatio,
      'recommendedIcon': getAdaptiveIcon(screenWidth, screenHeight),
      'recommendedSplash': getAdaptiveSplashScreen(screenWidth, screenHeight),
    };
  }
}

/// Extension pour faciliter l'utilisation
extension IOSAssetExtension on BoxConstraints {
  Map<String, dynamic> get iosDeviceInfo =>
      IOSAssetOptimizer.instance.getIOSDeviceInfo(this);
}
