import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './localisation_bubble.dart';

class LocationSelector extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final VoidCallback onSwap;
  final String pickupHint;
  final String destinationHint;

  // Palette calée sur le mock (tu peux ajuster finement si besoin)
  static const Color _outerBg = Color(0xFF11151B); // fond écran (réf)
  static const Color _container = Color(0xFF1A1F27); // cadre
  static const Color _stroke = Color(0xFF2B3039); // bord du cadre/pont
  static const Color _pill = Color(0xFF0F1319); // pilules très sombres
  static const Color _iconBg = Color(0xFF2B3039); // rond gris icône
  static const Color _icon = Color(0xFFFFFFFF); // icône blanche
  static const Color _text = Color(0xFFE6E7EB); // texte
  static const Color _hint = Color(0xFF9EA3AB); // hint gris
  static const Color _swapBg = Color(0xFF232733); // bouton swap
  static const Color _swapIcon = Color(0xFFE6E7EB);

  const LocationSelector({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.onSwap,
    this.pickupHint = 'Add a pick-up location',
    this.destinationHint = 'Add your destination',
  });

  void _haptic() => HapticFeedback.lightImpact();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _container,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stroke, width: 2), // cadre gris visible
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: SizedBox(
        height: 150, // hauteur calibrée sur l’image
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Espacement vertical entre pilules: calibré pour laisser le pont + bouton
            const double gap = 26;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Pont central (derrière le bouton)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: _stroke.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                      ),
                    ),
                  ),
                ),

                // Colonne des deux pilules
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocationBubble(
                      controller: pickupController,
                      hint: pickupHint,
                      icon: Icons.place_rounded,
                      pillColor: _pill,
                      iconBgColor: _iconBg,
                      iconColor: _icon,
                      textColor: _text,
                      hintColor: _hint,
                    ),
                    const SizedBox(height: gap),
                    LocationBubble(
                      controller: destinationController,
                      hint: destinationHint,
                      icon: Icons.place_rounded,
                      pillColor: _pill,
                      iconBgColor: _iconBg,
                      iconColor: _icon,
                      textColor: _text,
                      hintColor: _hint,
                    ),
                  ],
                ),

                // Bouton swap circulaire encastré
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _haptic();
                    final tmp = pickupController.text;
                    pickupController.text = destinationController.text;
                    destinationController.text = tmp;
                    onSwap();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _swapBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: _stroke, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: _swapIcon,
                      size: 20,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
