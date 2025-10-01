import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AdminTokenService {
  static final AdminTokenService _instance = AdminTokenService._internal();
  factory AdminTokenService() => _instance;
  AdminTokenService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Sauvegarder le token FCM de l'admin
  Future<void> saveAdminToken(String adminId) async {
    try {
      print('🔔 AdminTokenService: Sauvegarde du token pour admin $adminId');
      
      // Obtenir le token FCM
      String? token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        // Sauvegarder dans Firestore
        await _firestore.collection('admin_tokens').doc(adminId).set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': 'android', // ou 'ios'
        });
        
        print('🔔 AdminTokenService: Token sauvegardé: $token');
      } else {
        print('🔔 AdminTokenService: Impossible d\'obtenir le token FCM');
      }
    } catch (e) {
      print('🔔 AdminTokenService: Erreur sauvegarde token: $e');
    }
  }

  // Récupérer le token FCM de l'admin
  Future<String?> getAdminToken(String adminId) async {
    try {
      print('🔔 AdminTokenService: Récupération du token pour admin $adminId');
      
      final doc = await _firestore.collection('admin_tokens').doc(adminId).get();
      
      if (doc.exists) {
        final token = doc.data()?['token'] as String?;
        print('🔔 AdminTokenService: Token récupéré: $token');
        return token;
      } else {
        print('🔔 AdminTokenService: Aucun token trouvé pour cet admin');
        return null;
      }
    } catch (e) {
      print('🔔 AdminTokenService: Erreur récupération token: $e');
      return null;
    }
  }

  // Récupérer tous les tokens admin (pour envoyer à tous les admins)
  Future<List<String>> getAllAdminTokens() async {
    try {
      print('🔔 AdminTokenService: Récupération de tous les tokens admin');
      
      final snapshot = await _firestore.collection('admin_tokens').get();
      final tokens = <String>[];
      
      for (final doc in snapshot.docs) {
        final token = doc.data()['token'] as String?;
        if (token != null) {
          tokens.add(token);
        }
      }
      
      print('🔔 AdminTokenService: ${tokens.length} tokens récupérés');
      return tokens;
    } catch (e) {
      print('🔔 AdminTokenService: Erreur récupération tous tokens: $e');
      return [];
    }
  }

  // Mettre à jour le token quand il change
  void setupTokenRefresh(String adminId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('🔔 AdminTokenService: Token rafraîchi: $newToken');
      await saveAdminToken(adminId);
    });
  }
}

