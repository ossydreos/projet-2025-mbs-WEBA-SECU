import 'package:flutter/material.dart';

class PaymentSuccessAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final String message;

  const PaymentSuccessAnimation({
    Key? key,
    this.onAnimationComplete,
    this.message = 'Paiement confirmé !',
  }) : super(key: key);

  @override
  State<PaymentSuccessAnimation> createState() => _PaymentSuccessAnimationState();
}

class _PaymentSuccessAnimationState extends State<PaymentSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _fadeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation de l'échelle (cercle qui grandit) - PLUS RAPIDE
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Animation de la coche (flèche qui apparaît) - PLUS LONGTEMPS
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));

    // Animation de disparition
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Démarrer les animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Démarrer l'animation du cercle
    await _scaleController.forward();
    
    // Attendre un peu puis démarrer la coche - PLUS RAPIDE
    await Future.delayed(const Duration(milliseconds: 100));
    await _checkController.forward();
    
    // Attendre puis disparaître - PLUS LONGTEMPS POUR BIEN VOIR
    await Future.delayed(const Duration(milliseconds: 3000));
    await _fadeController.forward();
    
    // Appeler le callback
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _checkAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation du cercle et de la coche
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle vert qui grandit
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.green,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    // Cercle intérieur
                    Transform.scale(
                      scale: _scaleAnimation.value * 0.7,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    // Coche/Flèche
                    Transform.scale(
                      scale: _checkAnimation.value,
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Message de succès
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 10),
                
                // Message secondaire
                const Text(
                  'Votre réservation est confirmée',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget pour afficher l'animation en overlay
class PaymentSuccessOverlay extends StatefulWidget {
  final String message;
  final Duration duration;

  const PaymentSuccessOverlay({
    Key? key,
    this.message = 'Paiement confirmé !',
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<PaymentSuccessOverlay> createState() => _PaymentSuccessOverlayState();
}

class _PaymentSuccessOverlayState extends State<PaymentSuccessOverlay> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss après la durée spécifiée
    Future.delayed(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: PaymentSuccessAnimation(
          message: widget.message,
          onAnimationComplete: () {
            // Auto-dismiss après l'animation
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          },
        ),
      ),
    );
  }
}

// Fonction utilitaire pour afficher l'animation
void showPaymentSuccessAnimation(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PaymentSuccessOverlay(
      message: message ?? 'Paiement confirmé !',
    ),
  );
}
