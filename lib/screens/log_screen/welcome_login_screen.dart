import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_mobility_services/constants.dart';
import 'package:my_mobility_services/screens/log_screen/login_form.dart';
import 'package:my_mobility_services/screens/log_screen/signup_form.dart';
import 'package:my_mobility_services/widgets/log_screen/glass_sheet.dart';
import 'package:my_mobility_services/theme/theme_app.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart'
    hide GlassSheet;

enum PanelType { none, login, signup }

class WelcomeLoginSignup extends StatefulWidget {
  const WelcomeLoginSignup({super.key});

  @override
  State<WelcomeLoginSignup> createState() => _WelcomeLoginSignupState();
}

class _WelcomeLoginSignupState extends State<WelcomeLoginSignup>
    with SingleTickerProviderStateMixin {
  PanelType _panelType = PanelType.none;

  late final AnimationController _animationController; // contrôle global
  late final Animation<double> _fadeAnimation; // pour le scrim (fondu)
  late final Animation<Offset> _slideAnimation; // pour SlideTransition

  void _openPanel(PanelType type) {
    setState(() => _panelType = type);
    _animationController.forward(from: 0);
  }

  void _closePanel() {
    _animationController.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() => _panelType = PanelType.none);
    });
  }

  bool get _isSheetVisible => _panelType != PanelType.none;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final sheetHeight =
        MediaQuery.of(context).size.height * AppConstants.sheetRatio;
    final delta = details.primaryDelta ?? 0.0;
    final fraction = delta / sheetHeight;

    _animationController.value = (_animationController.value - fraction).clamp(
      0.0,
      1.0,
    );
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;

    if (velocity > 700) {
      _closePanel();
      return;
    }

    if (velocity < -700) {
      _animationController.forward();
      return;
    }

    if (_animationController.value > 0.5) {
      _animationController.forward();
    } else {
      _closePanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/MBG-Logo.svg',
                        height: 86,
                        semanticsLabel: 'Logo MBG',
                        colorFilter: const ColorFilter.mode(
                          Brand.accent,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome',
                        style: AppConstants.defaultTextStyle.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Réservez votre chauffeur en quelques secondes — moderne, fluide et fiable.',
                        textAlign: TextAlign.center,
                        style: AppConstants.defaultTextStyle.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

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
                            style: AppConstants.defaultTextStyle.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

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
                            style: AppConstants.defaultTextStyle.copyWith(
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

          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isSheetVisible,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closePanel,
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),
              ),
            ),
          ),

          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                behavior: HitTestBehavior.translucent,
                child: GlassSheet(
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  isSelected: false,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: switch (_panelType) {
                        PanelType.login => LoginForm(
                          onClose: _closePanel,
                          onSwitch: _openPanel,
                        ),
                        PanelType.signup => SignupForm(
                          onClose: _closePanel,
                          onSwitch: _openPanel,
                        ),
                        PanelType.none => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
