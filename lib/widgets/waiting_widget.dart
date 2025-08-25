import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// Loader "stroke drawing" : le logo se dessine, pause, s'efface, etc.
/// - Utilise ton asset: assets/images/MBG-Logo.svg
/// - Aucun glow, rendu net autour des lettres
class LoadingMBS extends StatefulWidget {
  const LoadingMBS({
    super.key,
    this.size = 120,
    this.color = const Color(0xFFDAFF34),
    this.strokeWidth = 2.2,
    this.duration = const Duration(milliseconds: 1800),
    this.pause = const Duration(milliseconds: 400),
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final Duration duration;
  final Duration pause;

  @override
  State<LoadingMBS> createState() => _LoadingMBSState();
}

class _LoadingMBSState extends State<LoadingMBS>
    with SingleTickerProviderStateMixin {
  String? _svgRaw; // SVG d'origine
  late final AnimationController _c; // 0..1
  // On va animer 0 -> 1 (dessin), pause, 1 -> 0 (efface), pause, loop
  late final Animation<double> _phase;

  static const double _dashLength =
      1000; // valeur "grande" pour simuler longueur totale

  @override
  void initState() {
    super.initState();
    // Charge le SVG une seule fois
    rootBundle.loadString('assets/images/MBG-Logo.svg').then((s) {
      if (mounted) setState(() => _svgRaw = s);
    });

    // Timeline totale = aller + pause + retour + pause
    final totalMs =
        widget.duration.inMilliseconds * 2 + widget.pause.inMilliseconds * 2;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    )..repeat();

    // Courbe en 4 segments: dessine -> hold -> efface -> hold
    _phase = TweenSequence<double>([
      // 0.0 -> 1.0 : dessine
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeInOut),
        weight: widget.duration.inMilliseconds.toDouble(),
      ),
      // hold à 1.0
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: widget.pause.inMilliseconds.toDouble(),
      ),
      // 1.0 -> 0.0 : efface
      TweenSequenceItem(
        tween: ReverseCurveTween(Curves.easeInOut),
        weight: widget.duration.inMilliseconds.toDouble(),
      ),
      // hold à 0.0
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: widget.pause.inMilliseconds.toDouble(),
      ),
    ]).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_svgRaw == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return AnimatedBuilder(
      animation: _phase,
      builder: (context, _) {
        // On calcule le dashoffset courant (de "pleinement masqué" -> "pleinement visible")
        final dashOffset = (1.0 - _phase.value) * _dashLength;

        final svgStyled = _injectStrokeStyle(
          _svgRaw!,
          color: widget.color,
          strokeWidth: widget.strokeWidth,
          dashArray: _dashLength,
          dashOffset: dashOffset,
        );

        return SvgPicture.string(
          svgStyled,
          width: widget.size,
          height: widget.size,
        );
      },
    );
  }

  /// Injecte un <style> global pour forcer tous les paths à être en stroke,
  /// et anime stroke-dasharray / stroke-dashoffset.
  String _injectStrokeStyle(
    String rawSvg, {
    required Color color,
    required double strokeWidth,
    required double dashArray,
    required double dashOffset,
  }) {
    // Couleur en hex #RRGGBB (on ignore l'alpha ici, SVG gère l'opacité via stroke-opacity)
    final hex =
        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';

    // Style CSS : on cible paths + shapes courants. On neutralise les fills.
    const styleOpen = '<style type="text/css"><![CDATA[';
    final styleCss =
        '''
      path, rect, circle, ellipse, line, polyline, polygon {
        fill: transparent !important;
        stroke: $hex !important;
        stroke-width: ${strokeWidth}px !important;
        stroke-linecap: round;
        stroke-linejoin: round;
        stroke-dasharray: ${dashArray}px;
        stroke-dashoffset: ${dashOffset}px;
      }
    ''';
    const styleClose = ']]></style>';

    // On insère le style juste après l'ouverture de <svg ...>
    final insertIndex = rawSvg.indexOf('>'); // fin de la balise <svg ...>
    if (insertIndex != -1) {
      return rawSvg.substring(0, insertIndex + 1) +
          styleOpen +
          styleCss +
          styleClose +
          rawSvg.substring(insertIndex + 1);
    }
    // fallback si SVG bizarre
    return rawSvg;
  }
}

/// Petite util pour inverser une courbe (1-t)
class ReverseCurveTween extends Tween<double> {
  ReverseCurveTween(Curve curve) : super(begin: 1.0, end: 0.0) {
    this.curve = curve;
  }
  late final Curve curve;

  @override
  double lerp(double t) => begin! + (end! - begin!) * curve.transform(t);
}
