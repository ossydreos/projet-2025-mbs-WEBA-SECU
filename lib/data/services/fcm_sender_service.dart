import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

class FCMSenderService {
  static final FCMSenderService _instance = FCMSenderService._internal();
  factory FCMSenderService() => _instance;
  FCMSenderService._internal();

  // URL pour l'API V1 FCM
  static const String _fcmV1Url = 'https://fcm.googleapis.com/v1/projects/my-mobility-services/messages:send';

  // Obtenir un token d'accès pour l'API V1
  Future<String?> _getAccessToken() async {
    try {
      // Pour l'API V1, on utilise Firebase Functions ou un service account
      // Pour l'instant, on retourne null car on va utiliser Firebase Functions
      return null;
    } catch (e) {
      return null;
    }
  }

  // Envoyer une notification FCM via Firebase Functions (API V1)
  Future<void> sendNotificationToAdmin({
    required String clientName,
    required String reservationId,
    String? adminToken,
  }) async {
    
    // Si pas de token admin, on ne peut pas envoyer
    if (adminToken == null || adminToken.isEmpty) {
      return;
    }

    try {
      // Appeler Firebase Function pour envoyer la notification
      final response = await http.post(
        Uri.parse('https://us-central1-my-mobility-services.cloudfunctions.net/sendNotification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': adminToken,
          'title': 'Nouvelle réservation',
          'body': 'Nouvelle demande de $clientName',
          'data': {
            'type': 'new_reservation',
            'clientName': clientName,
            'reservationId': reservationId,
          },
        }),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
    }
  }

  // Obtenir le token FCM de l'admin (à implémenter selon votre logique)
  Future<String?> getAdminToken() async {
    // Pour l'instant, on retourne null
    // Tu devras implémenter la logique pour récupérer le token de l'admin
    // depuis Firestore ou une autre source
    return null;
  }

  // Méthode de test pour envoyer une notification
  Future<void> sendTestNotification() async {
    
    final adminToken = await getAdminToken();
    if (adminToken != null) {
      await sendNotificationToAdmin(
        clientName: 'Client Test',
        reservationId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        adminToken: adminToken,
      );
    } else {
    }
  }
}
