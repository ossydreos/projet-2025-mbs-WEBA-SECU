import 'package:flutter/material.dart';

/// AppTokens captures colors, typography, spacing, radii, elevations, and motion.
/// Implements ThemeExtension to enable dynamic theming and ergonomic access.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // Core palette
  final Color accent;
  final Color accentOn;
  final Color neutralSurface; // base background surface
  final Color neutralSurfaceElevated; // elevated background
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Liquid glass surfaces
  final Color glassTint; // overlay tint on top of blur
  final Color glassStroke; // subtle outline
  final List<BoxShadow> glassShadow; // soft outer glow
  final double glassBlurForeground; // e.g., 18–20
  final double glassBlurBackground; // e.g., 30–40
  final BorderRadius glassRadius;

  // Spacing scale (4-based)
  final double spaceXxs; // 4
  final double spaceXs;  // 8
  final double spaceSm;  // 12
  final double spaceMd;  // 16
  final double spaceLg;  // 24
  final double spaceXl;  // 32
  final double spaceXxl; // 48

  // Motion durations
  final Duration motionFast; // 120ms
  final Duration motionBase; // 200ms
  final Duration motionSlow; // 260ms

  // Typography
  final TextStyle display;
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle body;
  final TextStyle caption;

  const AppTokens({
    // palette
    required this.accent,
    required this.accentOn,
    required this.neutralSurface,
    required this.neutralSurfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    // glass
    required this.glassTint,
    required this.glassStroke,
    required this.glassShadow,
    required this.glassBlurForeground,
    required this.glassBlurBackground,
    required this.glassRadius,
    // spacing
    required this.spaceXxs,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.spaceXxl,
    // motion
    required this.motionFast,
    required this.motionBase,
    required this.motionSlow,
    // type
    required this.display,
    required this.title1,
    required this.title2,
    required this.body,
    required this.caption,
  });

  static AppTokens liquidGlassDark({Color? seedAccent}) {
    final accent = seedAccent ?? const Color(0xFF7C9CFF);
    return AppTokens(
      accent: accent,
      accentOn: Colors.white,
      neutralSurface: const Color(0xFF0B0E13),
      neutralSurfaceElevated: const Color(0xFF0F141B),
      textPrimary: const Color(0xFFE6EAF2),
      textSecondary: const Color(0xFFCAD3E0),
      textTertiary: const Color(0xFF9AA6B2),
      glassTint: const Color.fromRGBO(255, 255, 255, 0.12),
      glassStroke: const Color.fromRGBO(255, 255, 255, 0.16),
      glassShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 30,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
      ],
      glassBlurForeground: 18,
      glassBlurBackground: 36,
      glassRadius: BorderRadius.circular(20),
      spaceXxs: 4,
      spaceXs: 8,
      spaceSm: 12,
      spaceMd: 16,
      spaceLg: 24,
      spaceXl: 32,
      spaceXxl: 48,
      motionFast: const Duration(milliseconds: 120),
      motionBase: const Duration(milliseconds: 200),
      motionSlow: const Duration(milliseconds: 260),
      display: const TextStyle(fontSize: 48, fontWeight: FontWeight.w400, height: 1.1, letterSpacing: -0.2),
      title1: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500, height: 1.15, letterSpacing: -0.1),
      title2: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, height: 1.2, letterSpacing: -0.1),
      body: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.35, letterSpacing: -0.1),
      caption: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.0),
    );
  }

  static AppTokens liquidGlassLight({Color? seedAccent}) {
    final accent = seedAccent ?? const Color(0xFF0A84FF);
    return AppTokens(
      accent: accent,
      accentOn: Colors.white,
      neutralSurface: const Color(0xFFF5F7FA),
      neutralSurfaceElevated: const Color(0xFFFFFFFF),
      textPrimary: const Color(0xFF1B1D1F),
      textSecondary: const Color(0xFF3A3D42),
      textTertiary: const Color(0xFF6B7076),
      glassTint: const Color.fromRGBO(255, 255, 255, 0.18),
      glassStroke: const Color.fromRGBO(0, 0, 0, 0.08),
      glassShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 30,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
      ],
      glassBlurForeground: 18,
      glassBlurBackground: 36,
      glassRadius: BorderRadius.circular(20),
      spaceXxs: 4,
      spaceXs: 8,
      spaceSm: 12,
      spaceMd: 16,
      spaceLg: 24,
      spaceXl: 32,
      spaceXxl: 48,
      motionFast: const Duration(milliseconds: 120),
      motionBase: const Duration(milliseconds: 200),
      motionSlow: const Duration(milliseconds: 260),
      display: const TextStyle(fontSize: 48, fontWeight: FontWeight.w400, height: 1.1, letterSpacing: -0.2),
      title1: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500, height: 1.15, letterSpacing: -0.1),
      title2: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, height: 1.2, letterSpacing: -0.1),
      body: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.35, letterSpacing: -0.1),
      caption: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.0),
    );
  }

  @override
  AppTokens copyWith({
    Color? accent,
    Color? accentOn,
    Color? neutralSurface,
    Color? neutralSurfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? glassTint,
    Color? glassStroke,
    List<BoxShadow>? glassShadow,
    double? glassBlurForeground,
    double? glassBlurBackground,
    BorderRadius? glassRadius,
    double? spaceXxs,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? spaceXxl,
    Duration? motionFast,
    Duration? motionBase,
    Duration? motionSlow,
    TextStyle? display,
    TextStyle? title1,
    TextStyle? title2,
    TextStyle? body,
    TextStyle? caption,
  }) {
    return AppTokens(
      accent: accent ?? this.accent,
      accentOn: accentOn ?? this.accentOn,
      neutralSurface: neutralSurface ?? this.neutralSurface,
      neutralSurfaceElevated: neutralSurfaceElevated ?? this.neutralSurfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      glassTint: glassTint ?? this.glassTint,
      glassStroke: glassStroke ?? this.glassStroke,
      glassShadow: glassShadow ?? this.glassShadow,
      glassBlurForeground: glassBlurForeground ?? this.glassBlurForeground,
      glassBlurBackground: glassBlurBackground ?? this.glassBlurBackground,
      glassRadius: glassRadius ?? this.glassRadius,
      spaceXxs: spaceXxs ?? this.spaceXxs,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      spaceXxl: spaceXxl ?? this.spaceXxl,
      motionFast: motionFast ?? this.motionFast,
      motionBase: motionBase ?? this.motionBase,
      motionSlow: motionSlow ?? this.motionSlow,
      display: display ?? this.display,
      title1: title1 ?? this.title1,
      title2: title2 ?? this.title2,
      body: body ?? this.body,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentOn: Color.lerp(accentOn, other.accentOn, t) ?? accentOn,
      neutralSurface: Color.lerp(neutralSurface, other.neutralSurface, t) ?? neutralSurface,
      neutralSurfaceElevated: Color.lerp(neutralSurfaceElevated, other.neutralSurfaceElevated, t) ?? neutralSurfaceElevated,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      glassTint: Color.lerp(glassTint, other.glassTint, t) ?? glassTint,
      glassStroke: Color.lerp(glassStroke, other.glassStroke, t) ?? glassStroke,
      glassShadow: _lerpShadows(glassShadow, other.glassShadow, t),
      glassBlurForeground: _lerpDouble(glassBlurForeground, other.glassBlurForeground, t),
      glassBlurBackground: _lerpDouble(glassBlurBackground, other.glassBlurBackground, t),
      glassRadius: BorderRadius.lerp(glassRadius, other.glassRadius, t) ?? glassRadius,
      spaceXxs: _lerpDouble(spaceXxs, other.spaceXxs, t),
      spaceXs: _lerpDouble(spaceXs, other.spaceXs, t),
      spaceSm: _lerpDouble(spaceSm, other.spaceSm, t),
      spaceMd: _lerpDouble(spaceMd, other.spaceMd, t),
      spaceLg: _lerpDouble(spaceLg, other.spaceLg, t),
      spaceXl: _lerpDouble(spaceXl, other.spaceXl, t),
      spaceXxl: _lerpDouble(spaceXxl, other.spaceXxl, t),
      motionFast: _lerpDuration(motionFast, other.motionFast, t),
      motionBase: _lerpDuration(motionBase, other.motionBase, t),
      motionSlow: _lerpDuration(motionSlow, other.motionSlow, t),
      display: TextStyle.lerp(display, other.display, t) ?? display,
      title1: TextStyle.lerp(title1, other.title1, t) ?? title1,
      title2: TextStyle.lerp(title2, other.title2, t) ?? title2,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
    );
  }

  static List<BoxShadow> _lerpShadows(List<BoxShadow> a, List<BoxShadow> b, double t) {
    final int commonLength = a.length < b.length ? a.length : b.length;
    final result = <BoxShadow>[];
    for (var i = 0; i < commonLength; i++) {
      result.add(BoxShadow.lerp(a[i], b[i], t)!);
    }
    if (a.length > commonLength) {
      result.addAll(a.sublist(commonLength));
    } else if (b.length > commonLength) {
      result.addAll(b.sublist(commonLength));
    }
    return result;
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
  static Duration _lerpDuration(Duration a, Duration b, double t) =>
      Duration(milliseconds: (a.inMilliseconds + (b.inMilliseconds - a.inMilliseconds) * t).round());
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens {
    final ext = Theme.of(this).extension<AppTokens>();
    // Fallback to a sensible default to avoid null bang crashes when the extension
    // is not injected into ThemeData (e.g., during previews/tests or legacy themes).
    return ext ?? AppTokens.liquidGlassDark();
  }
}


