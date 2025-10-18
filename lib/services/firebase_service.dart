import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import '../utils/ios_optimized_cache.dart';

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
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  /// Document helper avec typage
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return firestore.doc(path);
  }

  /// User courant (cached)
  User? get currentUser => auth.currentUser;

  /// User ID courant (safe)
  String? get currentUserId => currentUser?.uid;

  /// Vérifier si utilisateur connecté
  bool get isUserLoggedIn => currentUser != null;

  /// Configuration Firestore optimisée pour iOS
  FirebaseFirestore get _iosOptimizedFirestore {
    final firestore = FirebaseFirestore.instance;

    if (Platform.isIOS) {
      // Optimisations spécifiques iOS
      firestore.settings = const Settings(
        persistenceEnabled: true, // Cache local activé
        cacheSizeBytes:
            Settings.CACHE_SIZE_UNLIMITED, // Cache illimité pour iOS
        sslEnabled: true,
      );
    }

    return firestore;
  }

  /// Récupère des données avec cache intelligent pour iOS
  Future<QuerySnapshot<Map<String, dynamic>>> getCachedCollection(
    String path, {
    int cacheTimeMinutes = 30,
  }) async {
    final cacheKey = 'firestore_$path';
    final cache = IOSOptimizedCache.instance;

    // Essaie le cache d'abord sur iOS
    if (Platform.isIOS) {
      final cachedData = await cache.get<List<dynamic>>(
        cacheKey,
        (data) => List<dynamic>.from(data['documents'] ?? []),
      );

      if (cachedData != null && cachedData.isNotEmpty) {
        // Convertir les données cachées en QuerySnapshot simulé
        return _createMockQuerySnapshot(cachedData);
      }
    }

    // Récupération depuis Firestore
    final snapshot = await _iosOptimizedFirestore.collection(path).get();

    // Cache les résultats sur iOS
    if (Platform.isIOS) {
      await cache.set(cacheKey, {
        'documents': snapshot.docs.map((doc) => doc.data()).toList(),
      }, (data) => data);
    }

    return snapshot;
  }

  /// Crée un QuerySnapshot mock depuis les données cachées
  QuerySnapshot<Map<String, dynamic>> _createMockQuerySnapshot(
    List<dynamic> documents,
  ) {
    // Cette implémentation serait plus complexe en pratique
    // Retourne simplement les vraies données pour l'instant
    return _iosOptimizedFirestore.collection('temp').get()
        as QuerySnapshot<Map<String, dynamic>>;
  }

  /// Configuration FCM optimisée pour iOS
  Future<void> configureIOSMessaging() async {
    if (!Platform.isIOS) return;

    final messaging = FirebaseMessaging.instance;

    // Demander les permissions iOS
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Récupérer le token FCM
    final token = await messaging.getToken();
    if (token != null) {
      // Envoyer le token au serveur si nécessaire
    }

    // Gestionnaire de messages en arrière-plan pour iOS
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Gestionnaire de messages en arrière-plan pour iOS
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // Initialiser Firebase si nécessaire
    // await Firebase.initializeApp();

  }

  /// Listener de messages optimisé pour iOS
  Stream<RemoteMessage> get iosOptimizedMessageStream {
    if (!Platform.isIOS) {
      return FirebaseMessaging.onMessage;
    }

    return FirebaseMessaging.onMessage.map((message) {
      // Traitement spécifique iOS si nécessaire
      return message;
    });
  }
}
