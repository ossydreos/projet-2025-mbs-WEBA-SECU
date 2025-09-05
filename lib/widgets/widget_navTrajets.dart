// lib/widgets/widget_navTrajets.dart
import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class TrajetNav extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final EdgeInsets margin;

  // Hauteur visible du composant (le Container qui contient le TabBar)
  static const double _barHeight = 56;

  const TrajetNav(
    this.controller, {
    this.margin = const EdgeInsets.symmetric(
      horizontal: 16,
    ), // même marge qu’avant
    super.key,
  });

  @override
  Size get preferredSize => Size.fromHeight(_barHeight + margin.vertical);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin, // ✅ marge comme ton ancien code
      height: _barHeight, // ✅ hauteur fixe identique
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.accent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab, // ✅
        labelColor: AppColors.textStrong, // ✅
        unselectedLabelColor: AppColors.textWeak, // ✅
        dividerColor: Colors.transparent, // ✅
        overlayColor: MaterialStateProperty.all(Colors.transparent), // ✅
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        tabs: const [
          Tab(text: 'À venir'),
          Tab(text: 'Terminés'),
        ],
      ),
    );
  }
}
