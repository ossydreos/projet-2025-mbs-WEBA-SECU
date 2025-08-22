import 'package:flutter/material.dart';

class SheetHandle extends StatelessWidget {
  // accept optional drag callbacks so parent can handle vertical drag
  const SheetHandle({
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    super.key,
  });

  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Center(
        child: Container(
          width: 44,
          height: 5,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.35),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}

// petit truc arrondi pour montrer qu'on peut descendre
