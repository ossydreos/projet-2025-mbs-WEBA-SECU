import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';

class FCMNotificationService {
  static final FCMNotificationService _instance =
      FCMNotificationService._internal();
  factory FCMNotificationService() => _instance;
  FCMNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _soundTimer;
  bool _isPlaying = false;
  int _soundCount = 0;
  static const Duration _soundInterval = Duration(seconds: 3);
  // Stop automatique quand la réservation change d'état
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _reservationStatusSubscription;

  // Stream pour écouter les messages FCM
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Future<void> initialize() async {
    print('🔔 FCMNotificationService: Initialisation...');

    // Demander les permissions
    await _requestPermissions();

    // Initialiser les notifications locales
    await _initializeLocalNotifications();

    // Configurer FCM
    await _configureFCM();

    print('🔔 FCMNotificationService: Initialisé avec succès');
  }

  Future<void> _requestPermissions() async {
    print('🔔 FCMNotificationService: Demande des permissions...');

    // Permission pour les notifications
    final notificationStatus = await Permission.notification.request();
    print('🔔 Permission notification: $notificationStatus');

    // Permission pour l'audio
    final audioStatus = await Permission.audio.request();
    print('🔔 Permission audio: $audioStatus');

    // Permission pour ignorer l'optimisation batterie (Android)
    if (Platform.isAndroid) {
      final batteryStatus = await Permission.ignoreBatteryOptimizations
          .request();
      print('🔔 Permission batterie: $batteryStatus');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    print('🔔 FCMNotificationService: Initialisation notifications locales...');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);
    await _createNotificationChannel();

    print('🔔 FCMNotificationService: Notifications locales initialisées');
  }

  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'uber_style_channel_v3',
        'Notifications Uber Style',
        description:
            'Notifications avec son répétitif pour les nouvelles réservations',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
        sound: const RawResourceAndroidNotificationSound('uber_classic_retro'),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      print('🔔 FCMNotificationService: Canal de notification créé');
    }
  }

  Future<void> _configureFCM() async {
    print('🔔 FCMNotificationService: Configuration FCM...');

    // Demander la permission pour les notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print(
      '🔔 FCMNotificationService: Statut permission: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 FCMNotificationService: Permissions accordées');

      // Obtenir le token FCM
      String? token = await _firebaseMessaging.getToken();
      print('🔔 FCMNotificationService: Token FCM: $token');

      // Messages au premier plan
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // L'écoute des messages en arrière-plan est enregistrée dans main.dart

      // Écouter les messages quand l'app est fermée
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      print('🔔 FCMNotificationService: FCM configuré avec succès');
    } else {
      print('🔔 FCMNotificationService: Permissions refusées');
    }
  }

  // Gérer les messages quand l'app est au premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print(
      '🔔 FCMNotificationService: Message reçu au premier plan: ${message.data}',
    );

    if (message.data['type'] == 'new_reservation') {
      await startUberStyleNotification(
        clientName: message.data['clientName'] ?? 'Client',
        reservationId: message.data['reservationId'] ?? '',
      );
    }
  }

  // Gérer les messages quand l'app est en arrière-plan
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print(
      '🔔 FCMNotificationService: Message reçu en arrière-plan: ${message.data}',
    );

    if (message.data['type'] == 'new_reservation') {
      // Créer une instance du service pour gérer la notification
      final service = FCMNotificationService();
      await service.startUberStyleNotification(
        clientName: message.data['clientName'] ?? 'Client',
        reservationId: message.data['reservationId'] ?? '',
      );
    }
  }

  // Gérer les messages quand l'app est ouverte depuis une notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print(
      '🔔 FCMNotificationService: App ouverte depuis notification: ${message.data}',
    );

    if (message.data['type'] == 'new_reservation') {
      // Arrêter la notification si l'admin ouvre l'app
      await stopNotification();
    }
  }

  Future<void> startUberStyleNotification({
    required String clientName,
    required String reservationId,
  }) async {
    print(
      '🔔 FCMNotificationService: Démarrage notification Uber style pour $clientName',
    );

    // Arrêter toute notification précédente
    await stopNotification();

    // Démarrer le son répétitif
    await _startSoundLoop();

    // Afficher la notification locale
    await _showLocalNotification(clientName, reservationId);

    // Écouter le statut de la réservation et arrêter si acceptée/refusée
    try {
      await _reservationStatusSubscription?.cancel();
    } catch (_) {}
    _reservationStatusSubscription = _firestore
        .collection('reservations')
        .doc(reservationId)
        .snapshots()
        .listen((doc) async {
          final data = doc.data();
          final status = data != null ? (data['status'] as String?) : null;
          if (status != null && status != 'pending') {
            await stopNotification();
          }
        });

    print('🔔 FCMNotificationService: Notification Uber style démarrée');
  }

  Future<void> _startSoundLoop() async {
    if (_isPlaying) return;

    _isPlaying = true;
    _soundCount = 0;

    print('🔔 FCMNotificationService: Démarrage boucle son');

    // Jouer le premier son immédiatement
    await _playNotificationSound();

    // Programmer les sons suivants
    _soundTimer = Timer.periodic(_soundInterval, (timer) async {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      await _playNotificationSound();
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      print('🔔 FCMNotificationService: Lecture son ${_soundCount + 1}');

      // Essayer de jouer le son personnalisé
      await _audioPlayer.play(AssetSource('sounds/uber_classic_retro.mp3'));

      _soundCount++;
      print('🔔 FCMNotificationService: Son joué avec succès');
    } catch (e) {
      print('🔔 FCMNotificationService: Erreur lecture son: $e');

      // Fallback vers le son système
      try {
        await _audioPlayer.play(AssetSource('sounds/system_alert.mp3'));
      } catch (e2) {
        print('🔔 FCMNotificationService: Erreur son système: $e2');
      }
    }
  }

  Future<void> _showLocalNotification(
    String clientName,
    String reservationId,
  ) async {
    print('🔔 FCMNotificationService: Affichage notification locale');

    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'uber_style_channel_v3',
      'Notifications Uber Style',
      channelDescription:
          'Notifications avec son répétitif pour les nouvelles réservations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('uber_classic_retro'),
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      ledColor: Color(0xFF4CAF50),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'uber_classic_retro.mp3',
      categoryIdentifier: 'uber_style_category',
      threadIdentifier: 'uber_style_thread',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      reservationId.hashCode,
      'Nouvelle demande de réservation',
      'Demande de $clientName',
      details,
    );

    print('🔔 FCMNotificationService: Notification locale affichée');
  }

  Future<void> stopNotification() async {
    print('🔔 FCMNotificationService: Arrêt notification');

    _isPlaying = false;
    _soundTimer?.cancel();
    _soundTimer = null;
    try {
      await _reservationStatusSubscription?.cancel();
    } catch (_) {}
    _reservationStatusSubscription = null;

    // Arrêter le son
    await _audioPlayer.stop();

    // Annuler toutes les notifications
    await _localNotifications.cancelAll();

    print('🔔 FCMNotificationService: Notification arrêtée');
  }

  // Méthode pour envoyer une notification de test
  Future<void> sendTestNotification() async {
    print('🔔 FCMNotificationService: Envoi notification de test');

    await startUberStyleNotification(
      clientName: 'Client Test',
      reservationId: 'test_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Obtenir le token FCM
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Envoyer une notification à l'administrateur
  Future<void> sendNotificationToAdmin(Reservation reservation) async {
    print(
      '🔔 FCMNotificationService: Envoi notification admin pour réservation ${reservation.id}',
    );

    // Ici on pourrait implémenter l'envoi de notification push à l'admin
    // Pour l'instant, on utilise juste les notifications locales
    await _showLocalNotification(
      'Nouvelle réservation',
      'Réservation de ${reservation.userName ?? 'Client'} pour ${reservation.destination}',
    );
  }

  // Envoyer une notification au client
  Future<void> sendNotificationToClient(Reservation reservation) async {
    print(
      '🔔 FCMNotificationService: Envoi notification client pour réservation ${reservation.id}',
    );

    // Ici on pourrait implémenter l'envoi de notification push au client
    // Pour l'instant, on utilise juste les notifications locales
    await _showLocalNotification(
      'Mise à jour réservation',
      'Votre réservation pour ${reservation.destination} a été mise à jour',
    );
  }

  // Nettoyer les ressources
  void dispose() {
    _messageSubscription?.cancel();
    _soundTimer?.cancel();
    _audioPlayer.dispose();
  }
}
