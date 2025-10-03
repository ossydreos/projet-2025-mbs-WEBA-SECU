import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Thème optimisé pour iOS avec les couleurs et styles natifs
class IOSTheme {
  static ThemeData get lightTheme {
    if (!Platform.isIOS) {
      return ThemeData.light(); // Retourne le thème par défaut sur Android
    }

    return ThemeData(
      // Palette de couleurs iOS
      primaryColor: CupertinoColors.activeBlue,
      primaryColorLight: const Color(0xFF34C759), // Vert iOS
      primaryColorDark: const Color(0xFF007AFF), // Bleu iOS plus foncé
      // Couleurs de surface
      scaffoldBackgroundColor: CupertinoColors.systemBackground,
      cardColor: CupertinoColors.secondarySystemBackground,

      // Couleurs de texte
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: CupertinoColors.label,
          fontSize: 34,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.41,
        ),
        displayMedium: TextStyle(
          color: CupertinoColors.label,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.36,
        ),
        displaySmall: TextStyle(
          color: CupertinoColors.label,
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.35,
        ),
        headlineLarge: TextStyle(
          color: CupertinoColors.label,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.38,
        ),
        headlineMedium: TextStyle(
          color: CupertinoColors.label,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: CupertinoColors.label,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: CupertinoColors.label,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: CupertinoColors.label,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
        ),
        bodyMedium: TextStyle(
          color: CupertinoColors.label,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        bodySmall: TextStyle(
          color: CupertinoColors.secondaryLabel,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.08,
        ),
      ),

      // Style des boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            CupertinoColors.activeBlue,
          ),
          foregroundColor: MaterialStateProperty.all(CupertinoColors.white),
          elevation: MaterialStateProperty.all(0),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),

      // Style des cartes
      cardTheme: CardThemeData(
        color: CupertinoColors.secondarySystemBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),

      // Style des AppBars
      appBarTheme: const AppBarTheme(
        backgroundColor: CupertinoColors.systemBackground,
        foregroundColor: CupertinoColors.label,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Style des inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CupertinoColors.systemGrey6,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CupertinoColors.activeBlue,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: CupertinoColors.placeholderText),
        hintStyle: const TextStyle(color: CupertinoColors.placeholderText),
      ),

      // Style des snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CupertinoColors.systemGrey,
        contentTextStyle: const TextStyle(color: CupertinoColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Animation et transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // Espacement et dimensions
      visualDensity: VisualDensity.compact,

      // Couleur des séparateurs
      dividerColor: CupertinoColors.systemGrey4,
    );
  }

  static ThemeData get darkTheme {
    if (!Platform.isIOS) {
      return ThemeData.dark();
    }

    return ThemeData(
      // Palette sombre iOS
      primaryColor: const Color(0xFF0A84FF),
      primaryColorLight: const Color(0xFF30D158),
      primaryColorDark: const Color(0xFF0A84FF),

      // Couleurs de surface sombres
      scaffoldBackgroundColor: CupertinoColors.black,
      cardColor: CupertinoColors.systemGrey6.darkColor,

      // Couleurs de texte sombres
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: CupertinoColors.white,
          fontSize: 34,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.41,
        ),
        displayMedium: TextStyle(
          color: CupertinoColors.white,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.36,
        ),
        displaySmall: TextStyle(
          color: CupertinoColors.white,
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.35,
        ),
        headlineLarge: TextStyle(
          color: CupertinoColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.38,
        ),
        headlineMedium: TextStyle(
          color: CupertinoColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: CupertinoColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: CupertinoColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: CupertinoColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
        ),
        bodyMedium: TextStyle(
          color: CupertinoColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        bodySmall: TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.08,
        ),
      ),

      // Autres styles similaires au thème clair mais adaptés au sombre
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(const Color(0xFF0A84FF)),
          foregroundColor: MaterialStateProperty.all(CupertinoColors.white),
          elevation: MaterialStateProperty.all(0),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: CupertinoColors.systemGrey6.darkColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: CupertinoColors.black,
        foregroundColor: CupertinoColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CupertinoColors.systemGrey5.darkColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 2),
        ),
        labelStyle: const TextStyle(color: CupertinoColors.systemGrey),
        hintStyle: const TextStyle(color: CupertinoColors.systemGrey),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: CupertinoColors.systemGrey2.darkColor,
        contentTextStyle: const TextStyle(color: CupertinoColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dividerColor: CupertinoColors.systemGrey,
    );
  }

  /// Applique le thème iOS à l'application
  static ThemeData getTheme({bool isDark = false}) {
    return isDark ? darkTheme : lightTheme;
  }
}

/// Extension pour utiliser facilement le thème iOS
extension IOSThemeExtension on BuildContext {
  bool get isIOS => Platform.isIOS;
  ThemeData get iosTheme => IOSTheme.getTheme();
  ThemeData get iosDarkTheme => IOSTheme.getTheme(isDark: true);
}
