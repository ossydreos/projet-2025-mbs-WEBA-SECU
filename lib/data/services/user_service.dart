import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../exceptions/app_exceptions.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection Firestore
  static const String _collection = 'users';

  // Créer ou mettre à jour un utilisateur
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e, stackTrace) {
      // CWE-209 CORRIGÉ : Log serveur uniquement
      developer.log(
        'Error creating/updating user',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
      );
      // Message générique pour l'utilisateur
      throw Exception('Impossible de sauvegarder les informations utilisateur');
    }
  }

  // Obtenir un utilisateur par UID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e, stackTrace) {
      // CWE-209 CORRIGÉ : Log serveur uniquement
      developer.log(
        'Error fetching user',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
      );
      // Retourne null au lieu d'exposer l'erreur
      return null;
    }
  }

  // Obtenir l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    return await getUserById(currentUser.uid);
  }

  // Vérifier si l'utilisateur actuel est admin
  Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }


  // Stream de l'utilisateur actuel
  Stream<UserModel?> getCurrentUserStream() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await getUserById(user.uid);
    });
  }
}
