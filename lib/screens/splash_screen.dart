import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SvgPicture.asset(
            'assets/images/MBG-Logo.svg',
            height: 86,
            semanticsLabel: 'Logo MBG',
            colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
