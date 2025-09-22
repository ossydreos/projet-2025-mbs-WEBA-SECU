import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/notification_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class TestNotificationDemo extends StatelessWidget {
  const TestNotificationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Démo Notification Uber'),
        backgroundColor: AppColors.bgElev,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 80,
                color: AppColors.accent,
              ),
              const SizedBox(height: 20),

              const Text(
                'Démo Notification Style Uber',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                'Cette démo montre la nouvelle notification plein écran avec effet de clignotement, options de contre-offre et d\'annulation.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () => _showTestNotification(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Lancer la démo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Fonctionnalités incluses :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Effet de clignotement sur tout l\'écran\n'
                      '• Interface plein écran style Uber\n'
                      '• Boutons ACCEPTER/REFUSER\n'
                      '• Option de contre-offre\n'
                      '• Animation de glissement\n'
                      '• Pulsation des boutons',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTestNotification(BuildContext context) {
    // Créer une réservation de test
    final testReservation = Reservation(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'demo_user',
      userName: 'Marie Dubois',
      vehicleName: 'Berline Premium',
      departure: 'Place de la Riponne, 1005 Lausanne',
      destination: 'Aéroport de Genève, 1215 Le Grand-Saconnex',
      selectedDate: DateTime.now().add(const Duration(hours: 1)),
      selectedTime: '16:45',
      estimatedArrival: '17:30',
      paymentMethod: 'Apple Pay',
      totalPrice: 52.80,
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      clientNote: 'Merci de venir à l\'entrée principale - Démo',
    );

    // Afficher la notification
    NotificationService.showUberStyleNotification(
      context,
      testReservation,
      onAccept: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Réservation acceptée !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onDecline: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Réservation refusée'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onCounterOffer: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🤝 Contre-offre proposée'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
