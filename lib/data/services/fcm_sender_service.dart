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
      print('🔔 FCMSenderService: Token d\'accès non implémenté (utilise Firebase Functions)');
      return null;
    } catch (e) {
      print('🔔 FCMSenderService: Erreur obtention token: $e');
      return null;
    }
  }

  // Envoyer une notification FCM via Firebase Functions (API V1)
  Future<void> sendNotificationToAdmin({
    required String clientName,
    required String reservationId,
    String? adminToken,
  }) async {
    print('🔔 FCMSenderService: Envoi notification via Firebase Functions');
    
    // Si pas de token admin, on ne peut pas envoyer
    if (adminToken == null || adminToken.isEmpty) {
      print('🔔 FCMSenderService: Pas de token admin disponible');
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
        print('🔔 FCMSenderService: Notification envoyée avec succès via Firebase Functions');
        print('🔔 FCMSenderService: Réponse: ${response.body}');
      } else {
        print('🔔 FCMSenderService: Erreur envoi notification: ${response.statusCode}');
        print('🔔 FCMSenderService: Réponse: ${response.body}');
      }
    } catch (e) {
      print('🔔 FCMSenderService: Erreur lors de l\'envoi: $e');
    }
  }

  // Obtenir le token FCM de l'admin (à implémenter selon votre logique)
  Future<String?> getAdminToken() async {
    // Pour l'instant, on retourne null
    // Tu devras implémenter la logique pour récupérer le token de l'admin
    // depuis Firestore ou une autre source
    print('🔔 FCMSenderService: Récupération token admin (non implémenté)');
    return null;
  }

  // Méthode de test pour envoyer une notification
  Future<void> sendTestNotification() async {
    print('🔔 FCMSenderService: Envoi notification de test');
    
    final adminToken = await getAdminToken();
    if (adminToken != null) {
      await sendNotificationToAdmin(
        clientName: 'Client Test',
        reservationId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        adminToken: adminToken,
      );
    } else {
      print('🔔 FCMSenderService: Impossible d\'envoyer la notification de test - pas de token admin');
    }
  }
}
