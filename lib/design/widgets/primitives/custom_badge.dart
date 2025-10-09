import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

/// Custom badge component for special reservation types
class CustomBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const CustomBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
  });

  /// Factory for "Demande personnalisée" badge
  factory CustomBadge.personalisee({VoidCallback? onTap}) {
    return CustomBadge(
      label: 'Demande personnalisée',
      backgroundColor: const Color(0xFFFFA726), // Amber/gold
      textColor: Colors.white,
      icon: Icons.star_rounded,
      onTap: onTap,
    );
  }

  /// Factory for custom offer badge
  factory CustomBadge.customOffer({VoidCallback? onTap}) {
    return CustomBadge(
      label: 'Offre personnalisée',
      backgroundColor: const Color(0xFF4CAF50), // Green
      textColor: Colors.white,
      icon: Icons.auto_awesome_rounded,
      onTap: onTap,
    );
  }

  /// Factory for counter offer badge
  factory CustomBadge.counterOffer({VoidCallback? onTap}) {
    return CustomBadge(
      label: 'Contre-offre',
      backgroundColor: const Color(0xFF2196F3), // Blue
      textColor: Colors.white,
      icon: Icons.swap_horiz_rounded,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bgColor = backgroundColor ?? t.accent;
    final txtColor = textColor ?? t.accentOn;

    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.spaceSm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: bgColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: txtColor,
                ),
                SizedBox(width: t.spaceXxs),
              ],
              Text(
                label,
                style: t.caption.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
