import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Vérifier si la session est encore valide
  Future<bool> isSessionValid() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Vérifier si l'utilisateur existe toujours dans Firestore
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _auth.signOut();
        return false;
      }

      final userData = userDoc.data();
      if (userData?['isActive'] == false) {
        // Utilisateur désactivé
        await _auth.signOut();
        return false;
      }

      return true;
    } catch (e) {
      print('Erreur lors de la vérification de session: $e');
      return false;
    }
  }

  // Déconnexion complète
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Mettre à jour la dernière connexion dans Firestore
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la dernière connexion: $e');
    }
  }
}
