import 'package:flutter/material.dart';
import 'dart:ui';

class GlassSheet extends StatelessWidget {
  const GlassSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            // Limite à 80% de la hauteur écran
            maxHeight: screenHeight * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.06),
            border: Border(
              top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
