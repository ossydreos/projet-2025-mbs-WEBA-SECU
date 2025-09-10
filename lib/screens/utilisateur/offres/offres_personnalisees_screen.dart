import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class OffresPersonnaliseesScreen extends StatelessWidget {
  final Function(int) onNavigate;
  final bool showBottomBar;

  const OffresPersonnaliseesScreen({
    super.key,
    required this.onNavigate,
    this.showBottomBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Offres Personnalisées',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 80,
                color: AppColors.accent,
              ),
              SizedBox(height: 20),
              Text(
                'Offres Personnalisées',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Bientôt disponible...',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
