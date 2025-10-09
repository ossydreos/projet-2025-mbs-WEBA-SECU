import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

/// Liquid Glass container with frosted blur, tint, inner top highlight,
/// soft outer glow, and optional noise overlay. Optimized with RepaintBoundary.
class GlassContainer extends StatefulWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? radius;
  final Color? tint;
  final double? blurSigma; // foreground blur
  final List<BoxShadow>? shadow;
  final bool interactiveScale;
  final bool showNoise;
  final String? noiseAsset; // optional tiled 64x64 noise texture
  final double noiseOpacity;

  const GlassContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.radius,
    this.tint,
    this.blurSigma,
    this.shadow,
    this.interactiveScale = true,
    this.showNoise = false,
    this.noiseAsset,
    this.noiseOpacity = 0.02,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final borderRadius = widget.radius ?? t.glassRadius;
    final blur = widget.blurSigma ?? t.glassBlurForeground;
    final tint = widget.tint ?? t.glassTint;
    final shadow = widget.shadow ?? t.glassShadow;

    final content = RepaintBoundary(
      child: AnimatedScale(
        scale: widget.interactiveScale && _pressed ? 0.98 : 1.0,
        duration: t.motionFast,
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          duration: t.motionFast,
          opacity: _pressed ? 0.98 : 1.0,
          curve: Curves.easeInOut,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: borderRadius,
                  boxShadow: shadow,
                  border: Border.all(color: t.glassStroke),
                ),
                child: Stack(
                  children: [
                    // Inner top highlight (1px gradient)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.00),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Optional noise overlay
                    if (widget.showNoise && widget.noiseAsset != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: widget.noiseOpacity,
                            child: Image.asset(
                              widget.noiseAsset!,
                              fit: BoxFit.none,
                              repeat: ImageRepeat.repeat,
                              filterQuality: FilterQuality.low,
                            ),
                          ),
                        ),
                      ),

                    // Content
                    if (widget.child != null)
                      Padding(
                        padding: widget.padding ?? EdgeInsets.all(t.spaceMd),
                        child: widget.child!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final wrapped = widget.margin == null
        ? content
        : Padding(padding: widget.margin!, child: content);

    if (!widget.interactiveScale) return wrapped;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: wrapped,
    );
  }
}


