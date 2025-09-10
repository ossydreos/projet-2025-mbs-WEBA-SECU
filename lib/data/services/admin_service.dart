import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ID de l'admin dans la base de données
  static const String _adminId = 'XIi0afPTqRZaGwrh6oBkArLCd813';
  static const String _collection = 'users';

  // Récupérer le numéro de téléphone de l'admin
  Future<String?> getAdminPhoneNumber() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_adminId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return data['number'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du numéro admin: $e');
    }
  }

  // Récupérer toutes les informations de l'admin
  Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_adminId).get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des informations admin: $e');
    }
  }

  // Stream des informations de l'admin (pour les mises à jour en temps réel)
  Stream<Map<String, dynamic>?> getAdminInfoStream() {
    return _firestore
        .collection(_collection)
        .doc(_adminId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }
}
