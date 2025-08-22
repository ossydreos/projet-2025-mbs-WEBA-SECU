// =============================================================
// Welcome / Login / Signup Screen (Refactor + Heavy Annotations)
// =============================================================
//
// ✅ Objectifs de ce refactor :
// - Mettre les fonctions en HAUT de la classe (openPanel, closePanel…)
// - Respecter les conventions de nommage Flutter/Dart (camelCase, _pourPrivé)
// - Factoriser et clarifier la structure : sections, widgets utilitaires, helpers
// - Ajouter des commentaires EXPlicites et utiles (en français)
// - Mettre un max de const pour des perfs et de la lisibilité
// - Garder la logique UI existante mais en plus clean
//
// 🔎 Notes :
// - On conserve le design (background dégradé + halo + glass sheet)
// - On améliore l’accessibilité (Semantics, tooltips, labels cohérents)
// - On isole quelques petites briques pour aérer la lecture

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/forms/login_form.dart';
import 'package:my_mobility_services/forms/signup_form.dart';
import 'package:my_mobility_services/widgets/buttons/social_buttons.dart';
import 'package:my_mobility_services/widgets/divider_text.dart';
import 'package:my_mobility_services/widgets/glass_sheet.dart';
import 'package:my_mobility_services/widgets/sheet_handle.dart';
import '../theme/theme_app.dart';

// ----------------------------
// Modèle simple d’état courant
// ----------------------------
enum PanelType { none, login, signup }

// =============================================================
// Widget racine : WelcomeLoginSignup
// =============================================================
class WelcomeLoginSignup extends StatefulWidget {
  const WelcomeLoginSignup({super.key});

  @override
  State<WelcomeLoginSignup> createState() => _WelcomeLoginSignupState();
}

class _WelcomeLoginSignupState extends State<WelcomeLoginSignup>
    with SingleTickerProviderStateMixin {
  // -----------------------------------------------------------
  // SECTION 1 — Champs privés (state) + contrôleurs d'anim
  // -----------------------------------------------------------
  // ⚠️ Noms privés avec underscore, camelCase, explicites.
  PanelType _panelType = PanelType.none;

  late final AnimationController _animationController; // contrôle global
  late final Animation<double> _fadeAnimation; // pour le scrim (fondu)

  // -----------------------------------------------------------
  // SECTION 2 — Fonctions (mises en HAUT comme demandé)
  // -----------------------------------------------------------
  /// Ouvre le panneau (login/signup) avec animation
  void _openPanel(PanelType type) {
    setState(() => _panelType = type);
    _animationController.forward(from: 0);
  }

  /// Ferme le panneau, puis remet l'état à `none` une fois l'anim terminée
  void _closePanel() {
    _animationController.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() => _panelType = PanelType.none);
    });
  }

  bool get _isSheetVisible => _panelType != PanelType.none;

  // -----------------------------------------------------------
  // SECTION 3 — Cycle de vie
  // -----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------
  // SECTION 4 — Build
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Police par défaut (Poppins) — on l’utilise partout via copyWith
    final defaultTextStyle = GoogleFonts.poppins();

    return Scaffold(
      body: Stack(
        children: [
          // Fond dégradé + halos (visuel d’accueil)
          _buildBackground(),

          // Contenu central « Welcome » (logo + tagline + CTA)
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo (SVG teinté par la couleur d’accent)
                      SvgPicture.asset(
                        'assets/images/MBG-Logo.svg',
                        height: 86,
                        semanticsLabel: 'Logo MBG',
                        colorFilter: const ColorFilter.mode(
                          AppColors.accent,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome',
                        style: defaultTextStyle.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Réservez votre chauffeur en quelques secondes — moderne, fluide et fiable.',
                        textAlign: TextAlign.center,
                        style: defaultTextStyle.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // CTA principal — Création de compte
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _openPanel(PanelType.signup),
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'Create Account',
                            style: defaultTextStyle.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CTA secondaire — Connexion
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => _openPanel(PanelType.login),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color.fromRGBO(255, 255, 255, 0.35),
                            ),
                          ),
                          child: Text(
                            'I already have an account',
                            style: defaultTextStyle.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SCRIM (fond sombre cliquable pour fermer la sheet)
          if (_isSheetVisible)
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _closePanel,
                child: Semantics(
                  label: 'Fermer le panneau',
                  button: true,
                  child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.45)),
                ),
              ),
            ),

          // SHEET coulissante (login/signup)
          AnimatedSlide(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            offset: _isSheetVisible ? Offset.zero : const Offset(0, 1),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GlassSheet(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: switch (_panelType) {
                      PanelType.login => LoginForm(onClose: _closePanel),
                      PanelType.signup => SignupForm(onClose: _closePanel),
                      PanelType.none => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // SECTION 5 — Widgets privés (lisibilité + réutilisation)
  // -----------------------------------------------------------
  /// Construit le fond dégradé + halos décoratifs.
  Widget _buildBackground() {
    return Stack(
      children: [
        // Dégradé principal
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Halo supérieur droit
        Positioned(
          right: -60,
          top: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(
                AppColors.accent.red,
                AppColors.accent.green,
                AppColors.accent.blue,
                0.12,
              ),
            ),
          ),
        ),
        // Halo inférieur gauche
        Positioned(
          left: -80,
          bottom: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(
                AppColors.accent.red,
                AppColors.accent.green,
                AppColors.accent.blue,
                0.08,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
