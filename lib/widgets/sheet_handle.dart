import 'package:flutter/material.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.35),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}
