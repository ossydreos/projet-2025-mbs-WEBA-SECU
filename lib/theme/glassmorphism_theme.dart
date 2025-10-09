// ===============================
// Glassmorphism Design System ✨ (DARK ONLY)
// lib/ui/glass/glassmorphism_theme.dart
// ===============================

import 'dart:ui';
import 'package:flutter/material.dart';

/// Palette — glass sur fond sombre (couleurs explicites)
class AppColors {
  // Base (dark) - Plus sombre pour cohérence avec welcome screen
  static const Color bg = Color(0xFF05070A); // near-black blue plus sombre
  static const Color bgElev = Color(0xFF080B0F);

  // Accents
  static const Color accent = Color(0xFF7C9CFF); // periwinkle
  static const Color accent2 = Color(0xFF4FE5D2); // aqua mint
  static const Color hot = Color(0xFFFF9DB0); // warm highlight

  // Texte
  static const Color textStrong = Color(0xFFE6EAF2);
  static const Color text = Color(0xFFCAD3E0);
  static const Color textWeak = Color(0xFF9AA6B2);

  // Verre (plus lisible sur sombre)
  static const Color glass = Color.fromRGBO(255, 255, 255, 0.08);
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
      surface: AppColors.bgElev,
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      tertiary: AppColors.hot,
      onSurface: AppColors.text,
      onPrimary: Colors.white, // lisible sur periwinkle
      onSecondary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent, // Transparent pour permettre GlassBackground
      textTheme: _textTheme(Colors.white),
      inputDecorationTheme: _inputTheme(scheme),
      elevatedButtonTheme: _buttonTheme(scheme),
      // Supprime toute animation de transition entre pages
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
        },
      ),
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
      // Configuration pour les InkWell - même style que la page admin
      splashFactory: InkRipple.splashFactory,
      highlightColor: AppColors.accent.withOpacity(0.1),
      splashColor: AppColors.accent.withOpacity(0.2),
    );
  }

  static TextTheme _textTheme(Color base) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: base,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: base,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: base.withOpacity(0.9),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: base.withOpacity(0.9),
      ),
      bodyMedium: TextStyle(fontSize: 14, color: base.withOpacity(0.8)),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.primary.withOpacity(0.85);
          }
          return scheme.primary.withOpacity(0.95);
        }),
        foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
      ),
    );
  }

  /// Builder de transitions sans animation
  static const _noAnim = _NoAnimationPageTransitionsBuilder();
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
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
          colors: [Color(0xFF05070A), Color(0xFF0A0D12), Color(0xFF05070A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _RadialGlow(
              color: AppColors.accent.withOpacity(0.08),
              size: 320,
            ),
          ),
          Positioned(
            left: -80,
            bottom: -100,
            child: _RadialGlow(
              color: AppColors.accent2.withOpacity(0.06),
              size: 380,
            ),
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
            border: showBorder
                ? const Border.fromBorderSide(
                    BorderSide(color: AppColors.glassStroke),
                  )
                : null,
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
  final PreferredSizeWidget? bottom;
  final double height;
  final BorderRadius borderRadius;

  const GlassAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.bottom,
    this.height = 60,
    this.borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(16),
    ),
  }) : super(key: key);

  // ➜ Très important : on additionne la hauteur du bottom
  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          // style / mise en page
          elevation: 0,
          backgroundColor: Colors.white.withOpacity(0.04),
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textStrong,
          titleSpacing: 16,
          toolbarHeight: height,

          // contenu
          title: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
              fontFamily: 'Poppins',
            ),
          ),
          actions: actions,

          // ➜ on passe le bottom ici
          bottom: bottom,
        ),
      ),
    );
  }
}

/// Boutons
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary; // filled when true
  final Color? backgroundColor;
  final Color? textColor;
  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.primary = true,
    this.backgroundColor,
    this.textColor,
  });

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
        color: backgroundColor ?? Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: backgroundColor != null 
              ? backgroundColor!.withOpacity(0.3)
              : AppColors.glassStroke,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon, 
                  size: 18, 
                  color: textColor ?? AppColors.textStrong,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: textColor ?? AppColors.textStrong,
                ),
              ),
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

  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label, hintText: hint),
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
              border: Border(top: BorderSide(color: AppColors.glassStroke)),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
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

/// Composant d'alerte uniforme avec style glassmorphique
class GlassAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const GlassAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.icon,
    required this.iconColor,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textWeak,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GlassButton(
                  label: cancelText,
                  onPressed: onCancel ?? () => Navigator.pop(context),
                  primary: false,
                ),
                GlassButton(
                  label: confirmText,
                  onPressed: onConfirm ?? () => Navigator.pop(context),
                  primary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Méthode utilitaire pour afficher une alerte de confirmation
Future<bool?> showGlassConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  required String cancelText,
  required IconData icon,
  required Color iconColor,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => GlassAlertDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      iconColor: iconColor,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}

/// Composant d'alerte pour les actions multiples avec style glassmorphique
class GlassActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<GlassActionButton> actions;

  const GlassActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textWeak,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: action,
            )),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action pour les alertes
class GlassActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isPrimary;

  const GlassActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18, color: color) : const SizedBox.shrink(),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color ?? AppColors.glassStroke),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// (Demo page retirée)
