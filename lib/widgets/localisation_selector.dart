import 'package:flutter/material.dart';
import 'package:my_mobility_services/widgets/hexagon_shapes.dart';
import 'localisation_bubble.dart';
import '../theme/theme_app.dart';

class LocalisationSelector extends StatefulWidget {
  // ✨ Changé en StatefulWidget
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final VoidCallback onSwap;
  final String pickupHint;
  final String destinationHint;

  const LocalisationSelector({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.onSwap,
    required this.pickupHint,
    required this.destinationHint,
  });

  @override
  State<LocalisationSelector> createState() => _LocalisationSelectorState();
}

class _LocalisationSelectorState extends State<LocalisationSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // ✨ Configuration de l'animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500), // Animation de 500ms
      vsync: this,
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.5, // 0.5 = 180° (1.0 = 360°)
        ).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  // ✨ Fonction qui lance l'animation + ton action
  void _handleSwap() {
    _rotationController.forward().then((_) {
      _rotationController.reset(); // Remet à zéro pour la prochaine fois
    });

    widget.onSwap(); // ✨ Utilise widget.onSwap au lieu de onSwap
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface, // couleur bulle widget
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Bulle du haut (pickup)
              LocalisationBubble(
                controller: widget.pickupController, // ✨ Utilise widget.
                hintText: widget.pickupHint, // ✨ Utilise widget.
                iconColor: Colors.white,
                icon: Icons.my_location,
              ),

              const SizedBox(height: 16), // Espace entre les bulles
              // Bulle du bas (destination)
              LocalisationBubble(
                controller: widget.destinationController, // ✨ Utilise widget.
                hintText: widget.destinationHint, // ✨ Utilise widget.
                iconColor: Colors.white,
                icon: Icons.location_on,
              ),
            ],
          ),

          // Bouton swap avec espace autour
          Positioned(
            top: 44, // Positionné entre les deux bulles
            left: 0,
            right: 0,
            child: Center(
              child: ClipPath(
                clipper: RoundedHexagonClipper(cornerRadius: 1.0),
                child: Container(
                  width: 65, // Largeur de la zone grise autour
                  height: 34, // Hauteur de la zone grise
                  decoration: BoxDecoration(
                    color: AppColors.surface, // fond contour bulle échange
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: _handleSwap, // ✨ Utilise la nouvelle fonction
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.background, // fond logo echange
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.background.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          // ✨ Animation ajoutée
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value * 2 * 3.14159,
                              child: const Icon(
                                Icons.cached,
                                color: Colors.white, // couleur logo echange
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
