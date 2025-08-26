import 'package:flutter/material.dart';

class LocationBubble extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color pillColor;
  final Color iconBgColor;
  final Color iconColor;
  final Color textColor;
  final Color hintColor;

  const LocationBubble({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.pillColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26), // pilule visuelle
      child: Container(
        height: 56,
        color: pillColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // pastille circulaire grisée + icône goutte
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: textColor, fontSize: 16),
                cursorColor: textColor,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: hintColor, fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
