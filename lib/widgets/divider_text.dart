import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DividerText extends StatelessWidget {
  const DividerText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    const c = Color.fromRGBO(255, 255, 255, 0.28);
    return Row(
      children: [
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: c)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: GoogleFonts.poppins(color: Colors.white70)),
        ),
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: c)),
        ),
      ],
    );
  }
}

// c'est comme le Or sign in with, il crée une ligne a gauche un texte puis un ligne a droite
