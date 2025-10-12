import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/notification_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).uberNotificationTest),
        backgroundColor: AppColors.bgElev,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test de la notification style Uber',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => _showTestNotification(context),
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
              child: const Text(
                'Afficher Notification Test',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Cette notification va clignoter et prendre tout l\'écran\ncomme dans l\'application Uber',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestNotification(BuildContext context) {
    // Créer une réservation de test
    final testReservation = Reservation(
      id: 'test_123',
      userId: 'user_123',
      userName: 'Jean Dupont',
      vehicleName: 'Berline Premium',
      departure: 'Gare de Lausanne, 1003 Lausanne',
      destination: 'Aéroport de Genève, 1215 Le Grand-Saconnex',
      selectedDate: DateTime.now().add(const Duration(hours: 2)),
      selectedTime: '14:30',
      estimatedArrival: '15:15',
      paymentMethod: 'Carte bancaire',
      totalPrice: 45.50,
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      clientNote: 'Merci de venir à l\'entrée principale',
    );

    // Afficher la notification
    NotificationService.showUberStyleNotification(
      context,
      testReservation,
      onAccept: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation acceptée !'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onDecline: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
  }
}
