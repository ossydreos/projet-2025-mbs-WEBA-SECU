import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialBtn extends StatelessWidget {
  const SocialBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 64, // zone cliquable
    this.iconSize = 35, // taille visuelle du logo
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SizedBox(width: iconSize, height: iconSize, child: icon),
          ),
        ),
      ),
    );

    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}
