import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_mobility_services/theme/theme_app.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SvgPicture.asset(
          'assets/images/MBG-Logo.svg',
          height: 86,
          semanticsLabel: 'Logo MBG',
          colorFilter: const ColorFilter.mode(
            AppColors.accent,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
