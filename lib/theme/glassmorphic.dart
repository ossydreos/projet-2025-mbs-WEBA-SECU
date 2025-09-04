import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
                  Brand.glass.withOpacity(0.9),
                  Brand.glass.withOpacity(0.7),
                ]
              : [
                  Brand.glass.withOpacity(0.7),
                  Brand.glass.withOpacity(0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Brand.accent.withOpacity(0.6) : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (isSelected)
            BoxShadow(color: Brand.accent.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}
