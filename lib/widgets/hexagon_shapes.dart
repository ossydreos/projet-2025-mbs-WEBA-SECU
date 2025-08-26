import 'package:flutter/material.dart';

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Points de l'hexagone (6 côtés)
    path.moveTo(width * 0.25, 0); // Point haut gauche
    path.lineTo(width * 0.75, 0); // Point haut droite
    path.lineTo(width, height * 0.5); // Point droite
    path.lineTo(width * 0.75, height); // Point bas droite
    path.lineTo(width * 0.25, height); // Point bas gauche
    path.lineTo(0, height * 0.5); // Point gauche
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ✨ NOUVELLE CLASSE - Ajoute celle-ci
class RoundedHexagonClipper extends CustomClipper<Path> {
  final double cornerRadius;

  RoundedHexagonClipper({this.cornerRadius = 6.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final radius = cornerRadius;

    // Hexagone avec coins arrondis
    path.moveTo(width * 0.25 + radius, 0);

    // Ligne du haut avec coin arrondi haut-droite
    path.lineTo(width * 0.75 - radius, 0);
    path.quadraticBezierTo(width * 0.75, 0, width * 0.85, height * 0.15);

    // Vers le point droit avec coin arrondi
    path.lineTo(width - radius * 0.3, height * 0.5 - radius * 0.5);
    path.quadraticBezierTo(
      width,
      height * 0.5,
      width - radius * 0.3,
      height * 0.5 + radius * 0.5,
    );

    // Vers le coin bas-droite avec arrondi
    path.lineTo(width * 0.85, height * 0.85);
    path.quadraticBezierTo(width * 0.75, height, width * 0.75 - radius, height);

    // Ligne du bas avec coin arrondi bas-gauche
    path.lineTo(width * 0.25 + radius, height);
    path.quadraticBezierTo(width * 0.25, height, width * 0.15, height * 0.85);

    // Vers le point gauche avec coin arrondi
    path.lineTo(radius * 0.3, height * 0.5 + radius * 0.5);
    path.quadraticBezierTo(
      0,
      height * 0.5,
      radius * 0.3,
      height * 0.5 - radius * 0.5,
    );

    // Retour au début avec coin arrondi haut-gauche
    path.lineTo(width * 0.15, height * 0.15);
    path.quadraticBezierTo(width * 0.25, 0, width * 0.25 + radius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HexagonPainter extends CustomPainter {
  final Color color;

  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Hexagone régulier
    path.moveTo(width * 0.25, 0);
    path.lineTo(width * 0.75, 0);
    path.lineTo(width, height * 0.5);
    path.lineTo(width * 0.75, height);
    path.lineTo(width * 0.25, height);
    path.lineTo(0, height * 0.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
