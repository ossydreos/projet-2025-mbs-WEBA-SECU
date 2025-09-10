import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginKey = 'last_login';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Vérifier si l'utilisateur veut rester connecté
  Future<bool> shouldRememberUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Sauvegarder la préférence "Rester connecté"
  Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, remember);
    
    if (remember) {
      // Sauvegarder la date de connexion
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    } else {
      // Supprimer la date de connexion si l'utilisateur ne veut pas rester connecté
      await prefs.remove(_lastLoginKey);
    }
  }

  // Vérifier si la session est encore valide
  Future<bool> isSessionValid() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final shouldRemember = await shouldRememberUser();
    if (!shouldRemember) {
      // Si l'utilisateur ne veut pas rester connecté, déconnecter
      await _auth.signOut();
      return false;
    }

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

  // Nettoyer les données de session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_lastLoginKey);
  }

  // Déconnexion complète
  Future<void> signOut() async {
    await _auth.signOut();
    await clearSession();
  }

  // Mettre à jour les préférences de session dans Firestore
  Future<void> updateUserSessionPreferences(String uid, bool rememberMe) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'rememberMe': rememberMe,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour des préférences de session: $e');
    }
  }
}
