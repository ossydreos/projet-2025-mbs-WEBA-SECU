import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingMBS extends StatefulWidget {
  const LoadingMBS({super.key, this.size = 120, this.color});

  final double size;
  final Color? color;

  @override
  State<LoadingMBS> createState() => _LoadingMBSState();
}

class _LoadingMBSState extends State<LoadingMBS>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 0 -> 180° rotation
    _angle = Tween<double>(
      begin: 0,
      end: math.pi,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFFDAFF34);
    final size = widget.size;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Transform.rotate(
          angle: _angle.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow simulé : logo flouté derrière
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: SvgPicture.asset(
                  'assets/images/MBG-Logo.svg',
                  width: size,
                  height: size,
                  colorFilter: ColorFilter.mode(
                    color.withOpacity(0.6), // un peu transparent
                    BlendMode.srcIn,
                  ),
                ),
              ),
              // Logo normal devant
              SvgPicture.asset(
                'assets/images/MBG-Logo.svg',
                width: size,
                height: size,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ],
          ),
        );
      },
    );
  }
}
