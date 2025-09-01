// lib/widgets/custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../theme/theme_app.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: AppColors.surface, // ✅ Surface sombre
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.accent.withOpacity(
                0.2,
              ), // ✅ Bordure accent subtile
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            top: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => onNavigate(0),
              ),
              _buildNavItem(
                icon: Icons.calendar_today,
                label: 'Trajets',
                isActive: currentIndex == 1,
                onTap: () => onNavigate(1),
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Compte',
                isActive: currentIndex == 2,
                onTap: () => onNavigate(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppColors
                      .accent // ✅ Couleur accent pour l'actif
                : AppColors
                      .textSecondary, // ✅ Couleur secondaire pour l'inactif
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? AppColors
                        .accent // ✅ Couleur accent pour l'actif
                  : AppColors
                        .textSecondary, // ✅ Couleur secondaire pour l'inactif
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.accent, // ✅ Indicateur accent
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
