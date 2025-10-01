import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/services/fcm_sender_service.dart';
import 'package:my_mobility_services/data/services/admin_token_service.dart';

class ReservationFCMService {
  static final ReservationFCMService _instance = ReservationFCMService._internal();
  factory ReservationFCMService() => _instance;
  ReservationFCMService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMSenderService _fcmSender = FCMSenderService();
  final AdminTokenService _adminTokenService = AdminTokenService();

  // Écouter les nouvelles réservations et envoyer des notifications FCM
  void startListeningForNewReservations() {
    print('🔔 ReservationFCMService: Démarrage écoute nouvelles réservations');
    
    _firestore
        .collection('reservations')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final reservationId = change.doc.id;
          
          print('🔔 ReservationFCMService: Nouvelle réservation détectée: $reservationId');
          
          // Envoyer notification FCM à tous les admins
          _sendNotificationToAllAdmins(
            clientName: data?['userName'] ?? 'Client',
            reservationId: reservationId,
            from: data?['departure'] ?? '',
            to: data?['destination'] ?? '',
            price: '${data?['totalPrice']?.toStringAsFixed(2) ?? '0.00'}€',
          );
        }
      }
    });
  }

  // Envoyer notification à tous les admins
  Future<void> _sendNotificationToAllAdmins({
    required String clientName,
    required String reservationId,
    required String from,
    required String to,
    required String price,
  }) async {
    try {
      print('🔔 ReservationFCMService: Envoi notification à tous les admins');
      
      // Récupérer tous les tokens admin
      final adminTokens = await _adminTokenService.getAllAdminTokens();
      
      if (adminTokens.isEmpty) {
        print('🔔 ReservationFCMService: Aucun token admin trouvé');
        return;
      }

      // Envoyer à chaque admin
      for (final token in adminTokens) {
        await _fcmSender.sendNotificationToAdmin(
          clientName: clientName,
          reservationId: reservationId,
          adminToken: token,
        );
      }
      
      print('🔔 ReservationFCMService: Notifications envoyées à ${adminTokens.length} admins');
    } catch (e) {
      print('🔔 ReservationFCMService: Erreur envoi notifications: $e');
    }
  }

  // Méthode pour envoyer une notification de test
  Future<void> sendTestNotification() async {
    print('🔔 ReservationFCMService: Envoi notification de test');
    
    await _sendNotificationToAllAdmins(
      clientName: 'Client Test',
      reservationId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      from: 'Point A',
      to: 'Point B',
      price: '25.00€',
    );
  }
}
