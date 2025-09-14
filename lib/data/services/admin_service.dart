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

}
