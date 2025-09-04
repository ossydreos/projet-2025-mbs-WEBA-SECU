import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:path_drawing/path_drawing.dart';

class LoadingMBS extends StatefulWidget {
  const LoadingMBS({
    super.key,
    this.size = 180,
    this.color = Brand.accent,
    this.letterDuration = const Duration(milliseconds: 800),
    this.gap = const Duration(milliseconds: 180),
    this.mOffset = Offset.zero,
    this.bOffset = Offset.zero,
    this.sOffset = Offset.zero,
    this.neonThicknessFactor = 0.02,
    this.glowIntensity = 0.1,
    this.spinDuration = const Duration(milliseconds: 1500),
  });

  final double size;
  final Color color;
  final Duration letterDuration;
  final Duration gap;
  final Offset mOffset, bOffset, sOffset;
  final double neonThicknessFactor;
  final double glowIntensity;
  final Duration spinDuration;

  @override
  State<LoadingMBS> createState() => _LoadingMBSState();
}

class _LoadingMBSState extends State<LoadingMBS> with TickerProviderStateMixin {
  late final AnimationController _traceC;
  late final AnimationController _spinC;

  static const String _M = r'''
m -251.49175,-6.4423387 c -0.65776,0.25744 -2.72839,1.452827 -4.60111,2.656417 -1.87298,1.2035899 -5.20435,3.28982896 -7.40304,4.63576496 -2.19895,1.34620004 -6.20051,3.81343904 -8.89264,5.48269504 -2.69214,1.6692606 -9.18105,5.6919817 -14.4198,8.9392117 -5.23875,3.24697 -10.23937,6.35079 -11.1125,6.89716 -0.87312,0.54636 -3.3139,2.06005 -5.42395,3.36364 -2.11006,1.30387 -6.33678,3.92033 -9.39271,5.81449 -3.05594,1.89441 -9.48531,5.86105 -14.2875,8.81538 -17.12093,10.53227 -16.00729,9.7581 -16.00729,11.12653 0,0.53895 0.24288,0.93265 0.85989,1.39409 1.64994,1.23401 14.3637,8.74209 15.61333,9.22046 1.57903,0.60431 3.81106,0.61833 5.28346,0.0328 0.62125,-0.24712 3.09431,-1.71476 5.4954,-3.26125 2.40109,-1.54676 7.28266,-4.69504 10.84792,-6.99612 3.56526,-2.30108 8.08963,-5.22128 10.05416,-6.4889 5.40359,-3.48695 21.39156,-13.82924 25.13542,-16.25944 5.19059,-3.36947 5.9301,-3.83011 6.01424,-3.74624 0.0431,0.0434 -0.55536,1.1983 -1.33032,2.56646 -0.77497,1.36843 -1.76874,3.14272 -2.20874,3.94309 -5.6179,10.22138 -16.02635,28.98325 -22.16336,39.95129 -1.83171,3.27395 -3.33057,6.15632 -3.33057,6.40582 0,0.60272 1.02394,1.53247 1.68751,1.53247 0.56039,0 4.02934,-1.02103 13.52603,-3.98119 3.20146,-0.998 9.5713,-2.94296 14.15521,-4.32223 21.57174,-6.49049 31.68359,-9.55516 35.45416,-10.74499 8.4127,-2.6551 20.17316,-6.11029 20.31498,-5.96874 0.045,0.0452 -0.45905,0.39899 -1.11998,0.78634 -0.66093,0.38735 -3.43456,2.21139 -6.16347,4.05368 -2.72892,1.84203 -8.06027,5.43878 -11.84725,7.9928 -22.61579,15.25191 -36.63765,24.95921 -37.78197,26.15645 -0.576,0.60245 -0.72734,0.9853 -0.66146,1.67269 0.0714,0.74904 0.31803,1.04643 1.54041,1.85817 2.08041,1.381653 14.01259,8.50715 14.89524,8.89476 1.22,0.53605 3.23083,0.40005 4.63868,-0.31326 0.69294,-0.35111 3.93329,-2.35321 7.2009,-4.44924 3.2676,-2.095757 8.26294,-5.28161 11.10059,-7.07945 6.06319,-3.84149 14.92832,-9.47897 21.43125,-13.62869 2.54662,-1.62507 6.8924,-4.38415 9.65729,-6.13093 2.7649,-1.74704 8.89662,-5.6216 13.62604,-8.61007 18.8222,-11.89355 24.46841,-15.51728 25.0534,-16.08058 0.86916,-0.83661 0.78211,-1.70153 -0.24871,-2.46777 -0.47307,-0.35163 -3.71739,-2.33865 -7.20989,-4.41536 -3.4925,-2.07698 -9.02891,-5.38957 -12.30313,-7.3615 -3.27422,-1.97168 -6.54844,-3.82191 -7.27604,-4.1111 -2.06507,-0.82127 -4.85749,-0.71199 -8.73125,0.34158 -6.25422,1.70127 -23.21322,6.46244 -33.99896,9.54537 -12.40631,3.54621 -18.61026,5.24642 -18.74467,5.13741 -0.0503,-0.0407 0.55748,-1.24354 1.35096,-2.67255 0.79322,-1.42928 2.07196,-3.7891 2.84136,-5.24431 0.76941,-1.45521 1.7833,-3.36021 2.25293,-4.23333 9.51018,-17.6821 13.88692,-26.1106711 13.88692,-26.7430227 0,-0.783431 -1.05622,-1.924315 -2.58683,-2.794 -0.83291,-0.473075 -5.08609,-2.997729 -9.45171,-5.61022504 -4.36563,-2.61249596 -8.53281,-5.02893496 -9.26042,-5.36998296 -1.6383,-0.768086 -4.18967,-0.824971 -5.95841,-0.132557
''';

  static const String _B = r'''
m -332.07426,143.73364 c -0.002,0.11007 -0.0312,5.75495 -0.0661,12.54416 l -0.0632,12.34361 4.23333,2.62757 c 2.32834,1.44489 8.63865,5.36866 14.02292,8.71908 9.63613,5.99626 15.21275,9.44087 25.13013,15.52284 3.04059,1.86452 5.29457,3.07949 5.71367,3.07949 1.26498,0 1.62772,-0.77126 1.89865,-4.03622 0.3302,-3.98224 0.0619,-12.31794 -0.46037,-14.30973 -0.88583,-3.37687 -2.53021,-6.31401 -4.69345,-8.38226 -0.68818,-0.65802 -3.18849,-2.37331 -5.55625,-3.81185 -2.36802,-1.43854 -6.74608,-4.10501 -9.72925,-5.92535 -9.36705,-5.71605 -16.12345,-9.82821 -20.50521,-12.48066 -2.32834,-1.40917 -5.51339,-3.35624 -7.07761,-4.32646 -1.56421,-0.97049 -2.84559,-1.67429 -2.84718,-1.56422 m -10e-4,-46.328545 c -0.046,2.511163 0.01,24.789345 0.0624,24.828505 0.0408,0.0304 7.21783,4.31721 15.94908,9.52606 8.73125,5.20911 16.41079,9.79937 17.06563,10.20101 8.56827,5.25489 13.15111,7.6618 14.58807,7.6618 0.95752,0 2.35426,-0.83846 2.81384,-1.68936 0.36989,-0.68448 0.46223,-1.82801 0.54345,-6.74185 0.11959,-7.20275 -0.14975,-9.44271 -1.46764,-12.20629 -1.62004,-3.39778 -2.83316,-4.3471 -13.85067,-10.83839 -5.30119,-3.12341 -11.06726,-6.52727 -12.81351,-7.56417 -1.74625,-1.0369 -4.96094,-2.9345 -7.14375,-4.2172 -2.18281,-1.28243 -6.42488,-3.80021 -9.42657,-5.59461 -5.71739,-3.417895 -6.31349,-3.735395 -6.32037,-3.365505 m -20.48589,-34.24238 c -0.36989,0.52758 -0.41196,6.43441 -0.41196,57.669125 v 57.0812 l 0.55642,1.4867 c 0.78766,2.10582 1.71714,3.03027 5.22393,5.19509 1.69572,1.04696 8.02428,4.99639 14.0634,8.7765 6.03911,3.78036 12.17083,7.60809 13.62604,8.50635 4.01585,2.47915 10.94396,6.81487 35.64864,22.30861 9.29984,5.83247 11.13287,6.69713 14.32057,6.75428 2.1328,0.0384 3.68088,-0.42968 5.461,-1.65073 1.87642,-1.28694 3.29803,-3.16019 4.03675,-5.31945 0.57758,-1.68725 0.59028,-2.0066 0.66886,-16.93334 0.0942,-17.8517 -0.14208,-21.2336 -1.83912,-26.32604 -1.72217,-5.16837 -5.5118,-10.92676 -8.88603,-13.50327 l -1.1258,-0.85963 1.78673,-0.71014 c 5.95577,-2.3667 8.70903,-5.24881 9.74434,-10.20101 0.35137,-1.67958 0.39846,-3.91452 0.31195,-14.81032 -0.0968,-12.24942 -0.12806,-12.92834 -0.6858,-14.94896 -1.90791,-6.91303 -4.84109,-11.32126 -10.49417,-15.77155 -3.11018,-2.44845 -2.0193,-1.77509 -21.03438,-12.984165 -3.56526,-2.10158 -7.79198,-4.57465 -9.39271,-5.4954 -1.60073,-0.92101 -4.45823,-2.59106 -6.35,-3.71131 -10.56984,-6.25977 -19.28733,-11.37099 -33.77617,-19.80379 -9.82398,-5.71765 -10.56005,-6.02298 -11.45249,-4.74875''';

  static const String _S = r'''
m -151.97537,62.226683 c -2.65377,1.6346 -7.97455,4.99428 -19.8337,12.52432 -4.00182,2.5408 -9.153,5.80284 -11.4472,7.24906 -2.29393,1.44621 -7.71128,4.87124 -12.03854,7.61126 -4.32699,2.73976 -9.29613,5.88434 -11.04238,6.98765 -1.74625,1.10331 -5.55625,3.519497 -8.46667,5.368927 -5.69913,3.62189 -14.84868,9.40435 -18.22556,11.51838 -2.70642,1.69412 -4.27725,3.09059 -5.00274,4.44685 l -0.5842,1.0922 -0.082,25.26771 c -0.0847,25.97255 -0.05,27.0256 0.94747,28.97187 2.74717,5.3594 10.38887,7.71102 17.52309,5.39274 2.24737,-0.73025 5.31442,-2.28283 8.1616,-4.13121 2.29817,-1.49198 16.57906,-10.93787 33.1134,-21.90273 4.87495,-3.23268 9.13897,-6.02113 9.47579,-6.19655 1.35414,-0.70511 1.37213,-0.56938 1.37213,10.42697 0,10.05522 -0.003,10.12005 -0.59532,10.98471 -0.67151,0.98133 -0.38814,0.78792 -37.2401,25.44153 -14.47932,9.68666 -27.59392,18.46554 -29.14332,19.50853 -2.0066,1.35069 -2.93926,2.15344 -3.24115,2.78976 -0.36883,0.77708 -0.42386,2.40268 -0.42386,12.50818 0,8.68098 0.0802,11.69511 0.3175,11.93244 0.17462,0.17463 0.65564,0.3175 1.06918,0.3175 0.7919,0 4.02802,-2.24075 27.71748,-19.19287 6.33016,-4.52967 20.79625,-14.87964 32.14688,-22.99996 11.35062,-8.12007 21.30002,-15.27361 22.10964,-15.89644 3.46578,-2.6662 5.76633,-6.04837 7.19032,-10.5701 0.57652,-1.83092 0.5842,-2.08359 0.66939,-22.09271 0.0907,-21.40426 0.0421,-22.48932 -1.12395,-25.05498 -1.78858,-3.93515 -6.55611,-6.22935 -11.21383,-5.39697 -2.64557,0.47281 -5.03661,1.73593 -12.39785,6.55002 -3.52451,2.30479 -8.34363,5.44063 -10.70927,6.9686 -2.36591,1.52797 -7.10221,4.60745 -10.52539,6.84345 -22.49646,14.69363 -21.05316,13.80834 -21.98317,13.48422 -0.56145,-0.19579 -0.80275,-0.48604 -0.91626,-1.10252 -0.0847,-0.46011 -0.11773,-5.71817 -0.0736,-11.68453 l 0.0802,-10.84791 0.71755,-1.10332 c 0.39476,-0.60695 1.10913,-1.39726 1.5875,-1.7563 1.55125,-1.16417 44.49551,-28.976647 45.09982,-29.208687 0.28601,-0.1098 0.35242,0.8345 0.35242,5.011487 0,4.65005 0.0466,5.18901 0.48392,5.58456 1.02844,0.9308 1.62296,0.62627 11.81921,-6.05288 5.98619,-3.921397 7.50014,-5.584037 8.46798,-9.299577 0.32782,-1.25915 0.39556,-4.01638 0.39556,-16.12847 v -14.6095 l -0.69718,-0.54822 c -0.38338,-0.30162 -0.8345,-0.54848 -1.00224,-0.54848 -0.16801,0 -1.43166,0.694 -2.80855,1.54199
''';

  @override
  void initState() {
    super.initState();

    final total =
        widget.letterDuration.inMilliseconds * 3 +
        widget.gap.inMilliseconds * 2;

    _traceC = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );

    _spinC = AnimationController(vsync: this, duration: widget.spinDuration);

    // ping-pong avec pause de 0.5s à chaque extrémité
    _spinC.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_spinC.status == AnimationStatus.completed) _spinC.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_spinC.status == AnimationStatus.dismissed) _spinC.forward();
        });
      }
    });

    _traceC.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // démarre la rotation avant -> arrière (le listener ci‑dessus gère la pause et l'inversion)
        _spinC.forward();
      }
    });

    _traceC.forward();
  }

  @override
  void dispose() {
    _traceC.dispose();
    _spinC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (parseSvgPathData(
      _M,
    )..fillType = PathFillType.evenOdd).shift(widget.mOffset);
    final b = (parseSvgPathData(
      _B,
    )..fillType = PathFillType.evenOdd).shift(widget.bOffset);
    final s = (parseSvgPathData(
      _S,
    )..fillType = PathFillType.evenOdd).shift(widget.sOffset);

    return CustomPaint(
      size: Size.square(widget.size),
      painter: _NeonTracePainter(
        progress: _traceC,
        rotation: _spinC,
        color: widget.color,
        m: m,
        b: b,
        s: s,
        letterDuration: widget.letterDuration,
        gap: widget.gap,
        thicknessFactor: widget.neonThicknessFactor,
        glowIntensity: widget.glowIntensity,
      ),
    );
  }
}

class _NeonTracePainter extends CustomPainter {
  _NeonTracePainter({
    required this.progress,
    required this.rotation,
    required this.color,
    required this.m,
    required this.b,
    required this.s,
    required this.letterDuration,
    required this.gap,
    required this.thicknessFactor,
    required this.glowIntensity,
  }) : super(repaint: Listenable.merge([progress, rotation]));

  final Animation<double> progress;
  final Animation<double> rotation;
  final Color color;
  final Path m, b, s;
  final Duration letterDuration, gap;
  final double thicknessFactor;
  final double glowIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    final group = Path()
      ..addPath(m, Offset.zero)
      ..addPath(b, Offset.zero)
      ..addPath(s, Offset.zero);
    final gb = group.getBounds();

    const pad = 8.0;
    final targetW = (size.width - pad * 2).clamp(1, double.infinity);
    final targetH = (size.height - pad * 2).clamp(1, double.infinity);

    final sx = targetW / (gb.width == 0 ? 1 : gb.width);
    final sy = targetH / (gb.height == 0 ? 1 : gb.height);
    final scale = sx < sy ? sx : sy;

    final tx = (size.width - gb.width * scale) / 2 - gb.left * scale;
    final ty = (size.height - gb.height * scale) / 2 - gb.top * scale;

    final mat = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale, scale);

    final mP = m.transform(mat.storage);
    final bP = b.transform(mat.storage);
    final sP = s.transform(mat.storage);

    final total = letterDuration.inMilliseconds * 3 + gap.inMilliseconds * 2;
    final t = progress.value * total;

    final slots = [
      (0, letterDuration.inMilliseconds), // M
      (
        letterDuration.inMilliseconds,
        letterDuration.inMilliseconds + gap.inMilliseconds,
      ),
      (
        letterDuration.inMilliseconds + gap.inMilliseconds,
        letterDuration.inMilliseconds * 2 + gap.inMilliseconds,
      ), // B
      (
        letterDuration.inMilliseconds * 2 + gap.inMilliseconds,
        letterDuration.inMilliseconds * 2 + gap.inMilliseconds * 2,
      ),
      (
        letterDuration.inMilliseconds * 2 + gap.inMilliseconds * 2,
        letterDuration.inMilliseconds * 3 + gap.inMilliseconds * 2,
      ), // S
    ];

    final isTracingDone = progress.status == AnimationStatus.completed;
    if (isTracingDone) {
      // rotation.value ∈ [0,1] -> angle direct 0..2π (et 2π..0 en reverse)
      final rv = rotation.value.clamp(0.0, 1.0);
      final angle = rv * 2 * math.pi; // 0..2π
      final c = Offset(size.width / 2, size.height / 2);
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.translate(-c.dx, -c.dy);
    }

    final baseStroke = (size.shortestSide * thicknessFactor).clamp(2.0, 32.0);
    final sigmaScale = baseStroke * glowIntensity;

    void drawNeonProgress(Path p, double start, double end) {
      double prog = 0;
      if (t >= end) {
        prog = 1;
      } else if (t > start) {
        prog = (t - start) / (end - start);
      }
      if (prog <= 0) return;

      final traced = _extractPartial(p, prog);

      final outer = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = baseStroke * 1.7
        ..color = color.withOpacity(0.30 * glowIntensity)
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          sigmaScale * 0.9,
        );

      final mid = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = baseStroke * 1.25
        ..color = color.withOpacity(0.55 * glowIntensity)
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          sigmaScale * 0.55,
        );

      final coreColor = Color.lerp(color, Colors.white, 0.25)!;
      final core = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = baseStroke * 0.85
        ..color = coreColor.withOpacity(0.95)
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          sigmaScale * 0.18,
        );

      final lineColor = Color.lerp(color, Colors.white, 0.35)!;
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = baseStroke * 0.55
        ..color = lineColor.withOpacity(0.95);

      canvas.drawPath(traced, outer);
      canvas.drawPath(traced, mid);
      canvas.drawPath(traced, core);
      canvas.drawPath(traced, line);
    }

    drawNeonProgress(mP, slots[0].$1.toDouble(), slots[0].$2.toDouble());
    drawNeonProgress(bP, slots[2].$1.toDouble(), slots[2].$2.toDouble());
    drawNeonProgress(sP, slots[4].$1.toDouble(), slots[4].$2.toDouble());
  }

  Path _extractPartial(Path p, double t) {
    t = t.clamp(0.0, 1.0);
    if (t <= 0) return Path();
    if (t >= 1) return p;

    double total = 0;
    for (final m in p.computeMetrics()) {
      total += m.length;
    }

    double remaining = total * t;
    final out = Path();
    for (final m in p.computeMetrics()) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0.0, m.length);
      out.addPath(m.extractPath(0, take), Offset.zero);
      remaining -= take;
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _NeonTracePainter old) =>
      old.progress != progress ||
      old.rotation != rotation ||
      old.color != color;
}
