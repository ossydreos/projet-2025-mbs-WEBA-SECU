import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class UberStyleSoundService {
  static final UberStyleSoundService _instance = UberStyleSoundService._internal();
  factory UberStyleSoundService() => _instance;
  UberStyleSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  Timer? _soundTimer;
  Timer? _notificationTimer;
  bool _isPlaying = false;
  String? _currentReservationId;
  int _soundCount = 0;
  static const int _maxSounds = 10; // Sonner 10 fois maximum (plus longtemps)
  static const Duration _soundInterval = Duration(seconds: 4); // Toutes les 4 secondes

  // Initialiser le service
  Future<void> initialize() async {
    
    try {
      // Demander les permissions
      await _requestPermissions();
      
      // Initialiser les notifications locales
      await _initializeLocalNotifications();
      
      // Démarrer l'écoute des réservations en arrière-plan
      _startBackgroundListening();
      
    } catch (e) {
    }
  }
  
  // Démarrer l'écoute en arrière-plan
  void _startBackgroundListening() {
    // Le service écoute déjà via AdminGlobalNotificationService
    // On s'assure juste qu'il est prêt
  }

  // Demander les permissions nécessaires
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Permission pour les notifications (Android 13+)
      final notificationStatus = await Permission.notification.request();
      
      // Permission pour les sons
      final audioStatus = await Permission.audio.request();
      
      // Permission pour ignorer l'optimisation de la batterie
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
    }
  }

  // Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }
  
  // Créer le canal de notification Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'uber_reservations',
      'Nouvelles Réservations',
      description: 'Notifications pour les nouvelles demandes de course',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      sound: null,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  // Démarrer la notification sonore répétée (style Uber)
  void startUberStyleNotification({
    required String reservationId,
    required String clientName,
    required String from,
    required String to,
    required String price,
  }) {
    
    // Arrêter toute notification en cours
    stopNotification();
    
    _currentReservationId = reservationId;
    _soundCount = 0;
    _isPlaying = true;

    // Démarrer la notification locale (pour l'arrière-plan)
    _showLocalNotification(clientName, from, to, price);
    
    // Démarrer le son répétitif
    _startSoundLoop();
    
    // Démarrer le timer de notification locale répétée
    _startNotificationLoop(clientName, from, to, price);
    
  }

  // Démarrer la boucle de son
  void _startSoundLoop() {
    
    // Jouer le premier son immédiatement
    _playNotificationSound();
    _soundCount++;
    
    _soundTimer = Timer.periodic(_soundInterval, (timer) {
      if (_soundCount >= _maxSounds || !_isPlaying) {
        timer.cancel();
        return;
      }
      
      _playNotificationSound();
      _soundCount++;
    });
  }

  // Jouer le son de notification
  void _playNotificationSound() {
    // Utiliser directement le son système pour l'instant
    SystemSound.play(SystemSoundType.alert);
  }

  // Démarrer la boucle de notifications locales
  void _startNotificationLoop(String clientName, String from, String to, String price) {
    _notificationTimer = Timer.periodic(_soundInterval, (timer) {
      if (_soundCount >= _maxSounds || !_isPlaying) {
        timer.cancel();
        return;
      }
      
      _showLocalNotification(clientName, from, to, price);
    });
  }

  // Afficher une notification locale
  void _showLocalNotification(String clientName, String from, String to, String price) {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'uber_reservations',
      'Nouvelles Réservations',
      channelDescription: 'Notifications pour les nouvelles demandes de course',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ongoing: true, // Notification persistante
      autoCancel: false,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      sound: null,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ledColor: Color(0xFF00FF00),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: null,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      _currentReservationId?.hashCode ?? 0,
      '🚗 Nouvelle demande de course',
      '$clientName\nDe: $from\nVers: $to\nPrix: $price',
      details,
      payload: _currentReservationId,
    );
  }

  // Arrêter la notification
  void stopNotification() {
    
    _isPlaying = false;
    _soundTimer?.cancel();
    _notificationTimer?.cancel();
    _soundTimer = null;
    _notificationTimer = null;
    
    // Arrêter le son
    _audioPlayer.stop();
    
    // Annuler les notifications locales
    if (_currentReservationId != null) {
      _localNotifications.cancel(_currentReservationId!.hashCode);
    }
    
    _currentReservationId = null;
    _soundCount = 0;
  }

  // Gérer le tap sur la notification
  void _onNotificationTapped(NotificationResponse response) {
    
    // Arrêter la notification sonore
    stopNotification();
    
    // TODO: Naviguer vers l'écran de gestion des réservations
    // ou afficher la notification Uber style
  }

  // Vérifier si une notification est en cours
  bool get isPlaying => _isPlaying;
  
  // Obtenir l'ID de la réservation courante
  String? get currentReservationId => _currentReservationId;

  // Nettoyer les ressources
  void dispose() {
    stopNotification();
    _audioPlayer.dispose();
  }
}
