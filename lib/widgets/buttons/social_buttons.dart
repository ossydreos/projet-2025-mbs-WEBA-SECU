import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialBtn extends StatelessWidget {
  const SocialBtn({required this.label, required this.icon, this.tooltip});
  final String label;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        // TODO: Implémenter le social sign-in correspondant
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(message: tooltip ?? label, child: Icon(icon, size: 20)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
