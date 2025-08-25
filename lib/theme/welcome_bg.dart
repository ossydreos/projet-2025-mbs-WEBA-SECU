import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/theme_app.dart';

Widget buildBackground() {
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
