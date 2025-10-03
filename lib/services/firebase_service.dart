import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service centralisé pour les instances Firebase
/// Évite la duplication de FirebaseFirestore.instance partout
class FirebaseService {
  static FirebaseService? _instance;
  FirebaseService._internal();
  
  static FirebaseService get instance {
    _instance ??= FirebaseService._internal();
    return _instance!;
  }

  // Propriétés Firestore avec cache
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  FirebaseMessaging? _messaging;

  /// Firestore instance avec lazy loading
  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Auth instance avec lazy loading
  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  /// Messaging instance avec lazy loading
  FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  /// Collection helper avec typage
  CollectionReference<T> collection<T>(String path) {
    return firestore.collection(path);
  }

  /// Document helper avec typage
  DocumentReference<T> doc<T>(String path) {
    return firestore.doc(path);
  }

  /// User courant (cached)
  User? get currentUser => auth.currentUser;

  /// User ID courant (safe)
  String? get currentUserId => currentUser?.uid;

  /// Vérifier si utilisateur connecté
  bool get isUserLoggedIn => currentUser != null;
}
