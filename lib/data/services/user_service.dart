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
      final exception = FirestoreException(
        'Erreur lors de la création/mise à jour de l\'utilisateur',
        originalError: e,
        stackTrace: stackTrace,
      );
      exception.logError('UserService');
      throw exception;
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
      final exception = FirestoreException(
        'Erreur lors de la récupération de l\'utilisateur',
        originalError: e,
        stackTrace: stackTrace,
      );
      exception.logError('UserService');
      throw exception;
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
