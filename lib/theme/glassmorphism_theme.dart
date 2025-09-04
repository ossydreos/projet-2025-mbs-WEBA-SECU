// ===============================
// Glassmorphism Design System ✨ (DARK ONLY)
// lib/ui/glass/glassmorphism_theme.dart
// ===============================

import 'dart:ui';
import 'package:flutter/material.dart';

/// Palette — glass sur fond sombre (couleurs explicites)
class AppColors {
  // Base (dark)
  static const Color bg = Color(0xFF0B0E13);   // near-black blue
  static const Color bgElev = Color(0xFF0F141B);

  // Accents
  static const Color accent  = Color(0xFF7C9CFF); // periwinkle
  static const Color accent2 = Color(0xFF4FE5D2); // aqua mint
  static const Color hot     = Color(0xFFFF9DB0); // warm highlight

  // Texte
  static const Color textStrong = Color(0xFFE6EAF2);
  static const Color text       = Color(0xFFCAD3E0);
  static const Color textWeak   = Color(0xFF9AA6B2);

  // Verre (plus lisible sur sombre)
  static const Color glass       = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color glassStroke = Color.fromRGBO(255, 255, 255, 0.16);
}

/// Rayons / blur / ombres
class Fx {
  static const Radius radiusL = Radius.circular(28);
  static const Radius radiusM = Radius.circular(20);
  static const double blurX = 20;
  static const double blurY = 20;

  static const List<BoxShadow> glow = [
    BoxShadow(
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
      color: Color(0x40000000),
    ),
  ];
}

/// THEME **DARK UNIQUEMENT**
class AppTheme {
  static ThemeData get glassDark {
    final scheme = const ColorScheme.dark(
      background: AppColors.bg,
      surface: AppColors.bgElev,
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      tertiary: AppColors.hot,
      onBackground: AppColors.text,
      onSurface: AppColors.text,
      onPrimary: Colors.white,   // lisible sur periwinkle
      onSecondary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      textTheme: _textTheme(Colors.white),
      inputDecorationTheme: _inputTheme(scheme),
      elevatedButtonTheme: _buttonTheme(scheme),
      cardTheme: CardThemeData(
        color: AppColors.glass,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassStroke),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textStrong,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static TextTheme _textTheme(Color base) {
    return TextTheme(
      displayLarge:   TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: base),
      displayMedium:  TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: base),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: base),
      titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base.withOpacity(0.9)),
      bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: base.withOpacity(0.9)),
      bodyMedium:     TextStyle(fontSize: 14, color: base.withOpacity(0.8)),
      labelLarge:     const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme scheme) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: 1),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glass,
      hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.55)),
      labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.85)),
      border: border(AppColors.glassStroke),
      enabledBorder: border(AppColors.glassStroke),
      focusedBorder: border(scheme.primary.withOpacity(0.70)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static ElevatedButtonThemeData _buttonTheme(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withOpacity(0.85);
          return scheme.primary.withOpacity(0.95);
        }),
        foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
      ),
    );
  }
}

/// Fond gradient sombre + halos discrets
class GlassBackground extends StatelessWidget {
  final Widget? child;
  const GlassBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0E13),
            Color(0xFF121826),
            Color(0xFF0B0E13),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _RadialGlow(color: AppColors.accent.withOpacity(0.18), size: 320),
          ),
          Positioned(
            left: -80,
            bottom: -100,
            child: _RadialGlow(color: AppColors.accent2.withOpacity(0.16), size: 380),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _RadialGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

/// Panneau verre
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final bool showBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = const BorderRadius.all(Fx.radiusM),
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: Fx.blurX, sigmaY: Fx.blurY),
        child: Container(
          margin: margin,
          padding: padding,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: borderRadius,
            border: showBorder ? const Border.fromBorderSide(BorderSide(color: AppColors.glassStroke)) : null,
            boxShadow: Fx.glow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// AppBar verre
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const GlassAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          title: Text(title),
          actions: actions,
          backgroundColor: Colors.white.withOpacity(0.04),
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textStrong,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Boutons
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary; // filled when true
  const GlassButton({super.key, required this.label, this.onPressed, this.icon, this.primary = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: AppColors.textStrong), const SizedBox(width: 8)],
              Text(label, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.textStrong)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inputs
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;

  const GlassTextField({super.key, this.controller, this.label, this.hint, this.keyboardType, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

/// BottomSheet verre
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final Widget child;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Fx.radiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: screenHeight * 0.7,
              maxHeight: screenHeight * 0.7,
            ),
            decoration: const BoxDecoration(
              color: AppColors.glass,
              border: Border(
                top: BorderSide(color: AppColors.glassStroke),
              ),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight * 0.7),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// (Demo page retirée)
