import 'package:flutter/material.dart';

class AppColors {
  static const background = Color.fromARGB(255, 0, 0, 0);
  static const surface = Color(0xFF2E3A47);
  static const textSecondary = Color(0xFF476582);
  static const accent = Color.fromARGB(
    255,
    218,
    255,
    52,
  ); //static const accent = Color.fromARGB(255, 183, 255, 49) VERT CITRON JAUNE 0xFF55FF99 MENTHE menthe CLAIRE 255,78,253,151,
}

class AppTheme {
  static ThemeData dark() {
    const cs = ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.textSecondary,
      surface: AppColors.surface,
      background: AppColors.background,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      cardColor: AppColors.surface,
      textTheme: const TextTheme(
        // adapte selon besoin
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSecondary),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
