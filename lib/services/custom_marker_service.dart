import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomMarkerService {
  static const double _markerSize = 160.0; // 2x plus grand (60 * 2)
  
  /// Crée une icône personnalisée pour la localisation de l'utilisateur
  static Future<BitmapDescriptor> createUserLocationIcon({
    Color backgroundColor = const Color(0xFF2196F3),
    Color iconColor = Colors.white,
    String? customIconPath,
  }) async {
    if (customIconPath != null) {
      // Si un chemin d'icône personnalisée est fourni, l'utiliser
      return await _createCustomIconFromAsset(customIconPath);
    } else {
      // Sinon, créer une icône par défaut avec le style de l'app
      return await _createDefaultUserLocationIcon(backgroundColor, iconColor);
    }
  }

  /// Crée une icône personnalisée pour la destination
  static Future<BitmapDescriptor> createDestinationIcon({
    Color backgroundColor = const Color(0xFFE53E3E),
    Color iconColor = Colors.white,
    String? customIconPath,
  }) async {
    if (customIconPath != null) {
      return await _createCustomIconFromAsset(customIconPath);
    } else {
      return await _createDefaultDestinationIcon(backgroundColor, iconColor);
    }
  }

  /// Crée une icône personnalisée pour le départ
  static Future<BitmapDescriptor> createDepartureIcon({
    Color backgroundColor = const Color(0xFF10B981),
    Color iconColor = Colors.white,
    String? customIconPath,
  }) async {
    if (customIconPath != null) {
      return await _createCustomIconFromAsset(customIconPath);
    } else {
      return await _createDefaultDepartureIcon(backgroundColor, iconColor);
    }
  }

  /// Crée une icône à partir d'un asset
  static Future<BitmapDescriptor> _createCustomIconFromAsset(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _markerSize.toInt(),
      targetHeight: _markerSize.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Crée l'icône par défaut pour la localisation de l'utilisateur
  static Future<BitmapDescriptor> _createDefaultUserLocationIcon(
    Color backgroundColor,
    Color iconColor,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;

    // Dessiner le cercle de fond
    paint.color = backgroundColor;
    canvas.drawCircle(
      Offset(_markerSize / 2, _markerSize / 2),
      _markerSize / 2 - 2,
      paint,
    );

    // Dessiner la bordure
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(
      Offset(_markerSize / 2, _markerSize / 2),
      _markerSize / 2 - 2,
      paint,
    );

    // Dessiner l'icône de localisation
    paint.color = iconColor;
    paint.style = PaintingStyle.fill;
    _drawLocationIcon(canvas, paint, _markerSize / 2, _markerSize / 2, _markerSize * 0.3);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(
      _markerSize.toInt(),
      _markerSize.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Crée l'icône par défaut pour la destination
  static Future<BitmapDescriptor> _createDefaultDestinationIcon(
    Color backgroundColor,
    Color iconColor,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;

    // Dessiner le cercle de fond
    paint.color = backgroundColor;
    canvas.drawCircle(
      Offset(_markerSize / 2, _markerSize / 2),
      _markerSize / 2 - 2,
      paint,
    );

    // Dessiner la bordure
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(
      Offset(_markerSize / 2, _markerSize / 2),
      _markerSize / 2 - 2,
      paint,
    );

    // Dessiner l'icône de destination (flag)
    paint.color = iconColor;
    paint.style = PaintingStyle.fill;
    _drawFlagIcon(canvas, paint, _markerSize / 2, _markerSize / 2, _markerSize * 0.3);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(
      _markerSize.toInt(),
      _markerSize.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Crée l'icône par défaut pour le départ
  static Future<BitmapDescriptor> _createDefaultDepartureIcon(
    Color backgroundColor,
    Color iconColor,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;

    // Dessiner le cercle de fond
    paint.color = backgroundColor;
    canvas.drawCircle(
      Offset(_markerSize / 2, _markerSize / 2),
      _markerSize / 2 - 2,
      paint,
    );

    // Dessiner la bordure
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(
      Offset(_markerSize / 2, _markerSize / 2),
      _markerSize / 2 - 2,
      paint,
    );

    // Dessiner l'icône de départ (play)
    paint.color = iconColor;
    paint.style = PaintingStyle.fill;
    _drawPlayIcon(canvas, paint, _markerSize / 2, _markerSize / 2, _markerSize * 0.3);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(
      _markerSize.toInt(),
      _markerSize.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Dessine l'icône de localisation
  static void _drawLocationIcon(Canvas canvas, Paint paint, double centerX, double centerY, double size) {
    final Path path = Path();
    final double radius = size * 0.4;
    
    // Cercle principal
    path.addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    
    // Point central
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.3, paint);
  }

  /// Dessine l'icône de drapeau
  static void _drawFlagIcon(Canvas canvas, Paint paint, double centerX, double centerY, double size) {
    final Path path = Path();
    final double width = size * 0.6;
    final double height = size * 0.4;
    
    // Rectangle du drapeau
    path.addRect(Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: width,
      height: height,
    ));
    
    // Bâton du drapeau
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX - width/2, centerY + height/2),
      Offset(centerX - width/2, centerY + size/2),
      paint,
    );
    
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  /// Dessine l'icône de lecture
  static void _drawPlayIcon(Canvas canvas, Paint paint, double centerX, double centerY, double size) {
    final Path path = Path();
    final double triangleSize = size * 0.6;
    
    // Triangle pointant vers la droite
    path.moveTo(centerX - triangleSize/2, centerY - triangleSize/2);
    path.lineTo(centerX + triangleSize/2, centerY);
    path.lineTo(centerX - triangleSize/2, centerY + triangleSize/2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
}
