import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

class LiquidGlassTheme {
  static ThemeData dark({Color? accent}) {
    final tokens = AppTokens.liquidGlassDark(seedAccent: accent);
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.accent,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.neutralSurface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: _textTheme(tokens),
      elevatedButtonTheme: _buttonTheme(tokens),
      inputDecorationTheme: _inputTheme(tokens),
      cardTheme: CardThemeData(
        color: tokens.glassTint,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: tokens.glassRadius,
          side: BorderSide(color: tokens.glassStroke),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
      splashFactory: InkRipple.splashFactory,
      highlightColor: tokens.accent.withOpacity(0.08),
      splashColor: tokens.accent.withOpacity(0.16),
    );
  }

  static ThemeData light({Color? accent}) {
    final tokens = AppTokens.liquidGlassLight(seedAccent: accent);
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.accent,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.neutralSurface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: _textTheme(tokens),
      elevatedButtonTheme: _buttonTheme(tokens),
      inputDecorationTheme: _inputTheme(tokens),
      cardTheme: CardThemeData(
        color: tokens.glassTint,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: tokens.glassRadius,
          side: BorderSide(color: tokens.glassStroke),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
      splashFactory: InkRipple.splashFactory,
      highlightColor: tokens.accent.withOpacity(0.06),
      splashColor: tokens.accent.withOpacity(0.12),
    );
  }

  static TextTheme _textTheme(AppTokens t) {
    return TextTheme(
      displayLarge: t.display.copyWith(color: t.textPrimary),
      titleLarge: t.title1.copyWith(color: t.textPrimary),
      titleMedium: t.title2.copyWith(color: t.textPrimary),
      bodyLarge: t.body.copyWith(color: t.textPrimary),
      bodyMedium: t.body.copyWith(color: t.textSecondary),
      bodySmall: t.caption.copyWith(color: t.textTertiary),
      labelLarge: t.caption.copyWith(color: t.textPrimary),
    );
  }

  static ElevatedButtonThemeData _buttonTheme(AppTokens t) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: t.spaceLg, vertical: t.spaceSm),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: t.glassRadius),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          final pressed = states.contains(WidgetState.pressed);
          return t.accent.withOpacity(pressed ? 0.9 : 0.96);
        }),
        foregroundColor: WidgetStateProperty.all(t.accentOn),
        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(AppTokens t) {
    return InputDecorationTheme(
      filled: true,
      fillColor: t.neutralSurfaceElevated.withOpacity(0.7),
      contentPadding: EdgeInsets.symmetric(
        horizontal: t.spaceMd,
        vertical: t.spaceSm,
      ),
      border: OutlineInputBorder(
        borderRadius: t.glassRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: t.glassRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: t.glassRadius,
        borderSide: BorderSide(color: t.accent, width: 2),
      ),
      hintStyle: t.body.copyWith(color: t.textTertiary),
      labelStyle: t.body.copyWith(color: t.textTertiary),
    );
  }
}


