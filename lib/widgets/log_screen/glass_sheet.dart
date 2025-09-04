import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_mobility_services/constants.dart';

class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    required bool isSelected,
  });

  final Widget child;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 👈 capte partout
      onVerticalDragUpdate: onVerticalDragUpdate, // 👈 fait bouger la sheet
      onVerticalDragEnd: onVerticalDragEnd,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: screenHeight * AppConstants.sheetRatio,
              maxHeight: screenHeight * AppConstants.sheetRatio,
            ),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.06),
              border: Border(
                top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
              ),
            ),
            // 👇 on garde pour gérer le clavier, mais on coupe le scroll
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // ⛔️ pas de scroll
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight * 0.7),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
