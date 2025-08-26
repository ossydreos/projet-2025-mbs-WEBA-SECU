import 'package:flutter/material.dart';
import '../theme/theme_app.dart';

class LocalisationBubble extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color iconColor;
  final IconData icon; // ✨ Paramètre manquant ajouté

  const LocalisationBubble({
    super.key,
    required this.controller,
    required this.hintText,
    required this.iconColor,
    required this.icon, // ✨ Correct maintenant
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.background, // fond bulle localisation
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          // Conteneur pour l'icône avec cercle
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26),
                bottomLeft: Radius.circular(26),
              ),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surface, // fond logo
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, // ✨ Utilise le paramètre au lieu de Icons.location_on
                  color: iconColor,
                  size: 18,
                ),
              ),
            ),
          ),

          // Zone de texte
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white, // couleur du texte
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Colors.white, // couleur du texte exemple
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
