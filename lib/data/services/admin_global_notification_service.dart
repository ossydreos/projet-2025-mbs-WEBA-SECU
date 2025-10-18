import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/notification_manager.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

class AdminGlobalNotificationService {
  static final AdminGlobalNotificationService _instance =
      AdminGlobalNotificationService._internal();
  factory AdminGlobalNotificationService() => _instance;
  AdminGlobalNotificationService._internal();

  final ReservationService _reservationService = ReservationService();
  final NotificationManager _notificationManager = NotificationManager();
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<QuerySnapshot>? _reservationSubscription;
  BuildContext? _globalContext;
  DateTime _lastSeenReservationAt = DateTime.now().subtract(
    const Duration(minutes: 5),
  );
  bool _isInitialized = false;
  bool _isPlaying = false;
  Timer? _soundTimer;
  Timer? _soundTimeoutTimer;
  Timer? _backgroundPollingTimer;
  int _soundCount = 0;
  static const Duration _soundInterval = Duration(seconds: 3);
  static const Duration _maxSoundDuration = Duration(minutes: 2); // Timeout après 2 minutes
  Map<String, dynamic>? _pendingNotification;
  Set<String> _processedReservations = <String>{};
  // ✅ Protection contre les doublons de traitement
  Set<String> _processingReservations = <String>{};
  static const bool _enableSystemNotifications = false;
  final Set<String> _dismissedReservations = <String>{};

  // Initialiser le service global pour l'admin
  void initialize(BuildContext context) {
    _globalContext = context;

    // Toujours mettre à jour le contexte, même si déjà initialisé

    // Vérifier immédiatement les réservations en attente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkPendingReservations();
    });
  }


  // Initialiser le service sans contexte (pour le démarrage global)
  Future<void> initializeGlobal() async {
    if (!_isInitialized) {
      _isInitialized = true;
      
      // Initialiser les notifications locales
      await _initializeLocalNotifications();
      
      // Vérifier si l'utilisateur est admin avant de démarrer le pooling
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
          // Démarrer le polling pour les notifications en arrière-plan
          _startBackgroundPolling();
          
          // Réinitialiser le timestamp pour capturer toutes les nouvelles réservations
          _lastSeenReservationAt = DateTime.now().subtract(
            const Duration(minutes: 1),
          );
          _processedReservations.clear();
          _startListeningToReservations();
        } else {
        }
      } else {
      }
    }
  }

  // Démarrer le polling en arrière-plan pour les notifications locales
  void _startBackgroundPolling() {
    
    // Annuler le timer existant s'il y en a un
    _backgroundPollingTimer?.cancel();
    
    // Vérifier toutes les 30 secondes pour les nouvelles réservations
    _backgroundPollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForNewReservationsBackground();
    });
  }

  // Vérifier les nouvelles réservations en arrière-plan
  Future<void> _checkForNewReservationsBackground() async {
    try {
      
      // Vérifier si l'utilisateur actuel est admin
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        // Arrêter immédiatement les sons si l'utilisateur n'est pas admin
        if (_isPlaying) {
          _stopLocalNotifications();
        }
        return;
      }
      
      
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .where('adminDismissed', isEqualTo: false)
          .get();


      // Si aucune réservation en attente, arrêter les sons
      if (snapshot.docs.isEmpty) {
        if (_isPlaying) {
          _stopLocalNotifications();
        }
        return;
      }

      for (var doc in snapshot.docs) {
        if (!_processedReservations.contains(doc.id)) {
          final rawData = doc.data();
          final reservationId = doc.id;
          final data = {...rawData, 'id': reservationId};
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          
          // Vérifier si c'est une nouvelle réservation (créée dans les 5 dernières minutes)
          if (createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 5)))) {
            _processedReservations.add(reservationId);
            _showLocalNotificationForReservation(data);
          }
        }
      }
    } catch (e) {
    }
  }

  // Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);
    await _createNotificationChannels();

  }

  // Créer les canaux de notification
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Canal pour les nouvelles réservations
      final AndroidNotificationChannel reservationChannel = AndroidNotificationChannel(
        'new_reservation_channel',
        'Nouvelles Réservations',
        description: 'Notifications pour les nouvelles demandes de réservation',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(reservationChannel);

    }
  }

  // Mettre à jour le contexte (nécessaire lors des changements de page)
  void updateContext(BuildContext context) {
    _globalContext = context;

    // Afficher la notification en attente si elle existe
    if (_pendingNotification != null) {
      _showNotificationForReservation(_pendingNotification!);
      _pendingNotification = null;
    }

    // Vérifier les réservations en attente manquées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkPendingReservations();
    });
  }

  // Forcer la vérification des nouvelles réservations (pour les tests)
  void forceCheckNewReservations() {
    _lastSeenReservationAt = DateTime.now().subtract(
      const Duration(minutes: 10),
    );
    _processedReservations.clear();
  }

  // Forcer l'arrêt des sons (pour le débogage)
  void forceStopSounds() {
    _stopLocalNotifications();
  }

  // Vérifier et afficher toutes les réservations en attente manquées
  Future<void> checkPendingReservations() async {
    if (_globalContext == null || !_globalContext!.mounted) {
      return;
    }

    try {

      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .where('adminDismissed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in snapshot.docs) {
        final rawData = doc.data();
        final reservationId = doc.id;
        final data = {...rawData, 'id': reservationId};

        // Vérifier si cette réservation a déjà été traitée
        if (_processedReservations.contains(reservationId)) {
          continue;
        }

        final createdAt = (data['createdAt'] as Timestamp).toDate();

        // Afficher les réservations créées dans les 10 dernières minutes
        if (createdAt.isAfter(
          DateTime.now().subtract(const Duration(minutes: 10)),
        )) {
          _processedReservations.add(reservationId);
          _showNotificationForReservation(data);
        }
      }
    } catch (e) {
    }
  }

  // Forcer l'affichage d'une notification (pour les tests)
  void forceShowNotification(Reservation reservation, {BuildContext? context}) {

    // Utiliser le contexte fourni ou le contexte global
    final contextToUse = context ?? _globalContext;

    if (contextToUse == null) {
      return;
    }

    if (!contextToUse.mounted) {
      return;
    }


    try {
      _notificationManager.showGlobalNotification(
        contextToUse,
        reservation,
        onAccept: () => _acceptReservation(reservation.id),
        onDecline: () => _showRefusalOptions(reservation),
        onCounterOffer: () => _showCounterOfferDialog(reservation),
      );
    } catch (e) {
    }
  }

  // Démarrer l'écoute des nouvelles réservations
  void _startListeningToReservations() {
    _reservationSubscription?.cancel();


    _reservationSubscription = FirebaseFirestore.instance
        .collection('reservations')
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .where('adminDismissed', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {

            for (final change in snapshot.docChanges) {

              if (change.type != DocumentChangeType.added) {
                
                // Si c'est une modification et que le statut n'est plus pending, arrêter la musique
                if (change.type == DocumentChangeType.modified) {
                  final data = {
                ...change.doc.data() as Map<String, dynamic>,
                'id': change.doc.id,
              };
                  final status = data['status'] as String?;
                  if (status != null && status != ReservationStatus.pending.name) {
                    _stopLocalNotifications();
                  }
                }
                continue;
              }

              final data = change.doc.data() as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              final status = data['status'] as String?;


              // Ne traiter que les nouvelles réservations en attente
              if (status != null && status == ReservationStatus.pending.name) {
                final reservationId = change.doc.id;

                // Vérifier si cette réservation a déjà été traitée
                if (_processedReservations.contains(reservationId)) {
                  continue;
                }


                // Vérifier si c'est une nouvelle réservation (créée après la dernière vue)
                // Réduire la marge à 1 seconde pour être plus réactif
                final timeDifference = createdAt
                    .difference(_lastSeenReservationAt)
                    .inSeconds;


                // Accepter les réservations créées dans les 5 dernières minutes ou plus récentes
                if (timeDifference > 1 ||
                    createdAt.isAfter(
                      DateTime.now().subtract(const Duration(minutes: 5)),
                    )) {

                  // Marquer comme traitée pour éviter les doublons
                  _processedReservations.add(reservationId);

                  // Mettre à jour le timestamp seulement si c'est vraiment plus récent
                  if (createdAt.isAfter(_lastSeenReservationAt)) {
                    _lastSeenReservationAt = createdAt;
                  }

                  _showNotificationForReservation(data);
                } else {
                }
              } else {
              }
            }
          },
          onError: (error) {
          },
        );
  }

  // Afficher la notification pour une réservation
  void _showNotificationForReservation(Map<String, dynamic> data) {

    // ✅ Protection contre les doublons de traitement
    final reservationId = data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (_processingReservations.contains(reservationId)) {
      return;
    }

    _processingReservations.add(reservationId);
    try {
      // Vérifier si l'utilisateur actuel est admin
      // Pour l'instant, on affiche toujours les notifications
      // TODO: Ajouter une vérification du rôle utilisateur ici

      // Toujours afficher une notification locale, même sans contexte
      _showLocalNotificationForReservation(data);

      // Si on a un contexte, afficher aussi l'interface admin
      if (_globalContext != null && _globalContext!.mounted) {
        _showAdminInterfaceNotification(data);
      } else {
        // Stocker la notification en attente pour l'afficher quand le contexte sera disponible
        _pendingNotification = data;
      }
    } finally {
      // ✅ Toujours nettoyer le tracking, même en cas d'erreur
      _processingReservations.remove(reservationId);
    }
  }

  // Afficher une notification locale du système
  Future<void> _showLocalNotificationForReservation(Map<String, dynamic> data) async {
    if (!_enableSystemNotifications) {
      return;
    }
    final userName = data['userName'] as String? ?? 'Client';
    final destination = data['destination'] as String? ?? 'Destination inconnue';
    final price = data['totalPrice']?.toString() ?? '0.00';
    final reservationId = data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final status = data['status'] as String?;


    // Vérifier que c'est bien une réservation en attente avant de jouer le son
    if (status == ReservationStatus.pending.name) {
      // Démarrer la musique répétitive seulement pour les réservations en attente
      await _startSoundLoop();
    } else {
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_reservation_channel',
      'Nouvelles Réservations',
      channelDescription: 'Notifications pour les nouvelles demandes de réservation',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      ongoing: false,
      autoCancel: true,
      category: AndroidNotificationCategory.transport,
      visibility: NotificationVisibility.public,
      ledColor: Color(0xFF4CAF50),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'reservation_category',
      threadIdentifier: 'reservation_thread',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      reservationId.hashCode,
      '🚗 Nouvelle réservation',
      'Demande de $userName vers $destination - $price€',
      details,
    );
  }

  // Afficher l'interface admin (si contexte disponible)
  void _showAdminInterfaceNotification(Map<String, dynamic> data) {

    // ✅ Protection du contexte - éviter les crashes
    if (_globalContext == null || !_globalContext!.mounted) {
      _pendingNotification = data;
      return;
    }

    final userName = data['userName'] as String? ?? 'Client';
    final from = data['departure'] as String? ?? '';
    final to = data['destination'] as String? ?? '';

    // Créer un objet Reservation à partir des données
    final reservation = Reservation.fromMap({
      'id': data['id'] ?? '',
      'userId': data['userId'] ?? '',
      'userName': userName,
      'vehicleName': data['vehicleName'] ?? '',
      'departure': from,
      'destination': to,
      'selectedDate': (data['selectedDate'] as Timestamp).toDate(),
      'selectedTime': data['selectedTime'] ?? '',
      'estimatedArrival': data['estimatedArrival'] ?? '',
      'paymentMethod': data['paymentMethod'] ?? '',
      'totalPrice': (data['totalPrice'] ?? 0.0).toDouble(),
      'status': ReservationStatus.pending,
      'createdAt': (data['createdAt'] as Timestamp).toDate(),
      'departureCoordinates': data['departureCoordinates'],
      'destinationCoordinates': data['destinationCoordinates'],
      'clientNote': data['clientNote'],
      'hasCounterOffer': data['hasCounterOffer'] ?? false,
      'driverProposedDate': data['driverProposedDate'] != null
          ? (data['driverProposedDate'] as Timestamp).toDate()
          : null,
      'driverProposedTime': data['driverProposedTime'],
      'adminMessage': data['adminMessage'],
      'promoCode': data['promoCode'],
      'discountAmount': data['discountAmount']?.toDouble(),
    });


    try {
      _notificationManager.showGlobalNotification(
        _globalContext!,
        reservation,
        onAccept: () {
          // Arrêter la notification quand l'admin répond
          _stopLocalNotifications();
          _acceptReservation(reservation.id);
        },
        onDecline: () {
          // Arrêter la notification quand l'admin répond
          _stopLocalNotifications();
          _showRefusalOptions(reservation);
        },
        onCounterOffer: () {
          // Arrêter la notification quand l'admin répond
          _stopLocalNotifications();
          _showCounterOfferDialog(reservation);
        },
      );

    } catch (e) {
    }
  }

  // Démarrer la boucle de son EN BOUCLE CONTINUE À FOND
  Future<void> _startSoundLoop() async {
    if (_isPlaying) {
      _stopLocalNotifications();
      // ✅ Attendre que l'arrêt soit complet pour éviter les conflits audio
      await Future.delayed(Duration(milliseconds: 100));
    }

    _isPlaying = true;
    _soundCount = 0;


    // Jouer le son EN BOUCLE CONTINUE immédiatement
    await _playNotificationSoundLoop();

    // Programmer l'arrêt automatique après le timeout
    _soundTimeoutTimer = Timer(_maxSoundDuration, () {
      _stopLocalNotifications();
    });
  }

  // Jouer le son en boucle continue À FOND
  Future<void> _playNotificationSoundLoop() async {
    if (!_isPlaying) return;

    try {

      // Configurer le volume à 100% (1.0)
      await _audioPlayer.setVolume(1.0);
      
      // Configurer le mode de lecture en boucle
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Jouer le son en boucle
      await _audioPlayer.play(AssetSource('sounds/uber_classic_retro.mp3'));

    } catch (e) {
    }
  }

  // Jouer le son de notification À FOND EN BOUCLE
  Future<void> _playNotificationSound() async {
    // Vérifier si on doit encore jouer le son
    if (!_isPlaying) {
      return;
    }

    try {

      // Configurer le volume à 100% (1.0)
      await _audioPlayer.setVolume(1.0);
      
      // Configurer le mode de lecture en boucle
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Essayer de jouer le son personnalisé
      await _audioPlayer.play(AssetSource('sounds/uber_classic_retro.mp3'));

      _soundCount++;
    } catch (e) {
      // Fallback vers le même son Uber (présent dans les assets)
      try {
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/uber_classic_retro.mp3'));
      } catch (e2) {
      }
    }
  }

  // Arrêter les notifications locales
  void _stopLocalNotifications() {
    _isPlaying = false;
    _soundCount = 0;
    _soundTimer?.cancel();
    _soundTimer = null;
    _soundTimeoutTimer?.cancel();
    _soundTimeoutTimer = null;
    
    // Arrêter le son en boucle
    _audioPlayer.stop();
    
    // Remettre le mode normal (pas en boucle)
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    
  }

  // Redémarrer le service pour un utilisateur admin
  Future<void> restartForAdmin() async {
    
    // Arrêter le pooling actuel
    _backgroundPollingTimer?.cancel();
    _backgroundPollingTimer = null;
    
    // Vérifier si l'utilisateur est admin
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        _startBackgroundPolling();
        _startListeningToReservations();
      } else {
        _stopLocalNotifications();
      }
    }
  }

  // Accepter une réservation (délègue à l'écran de réception pour la même logique)
  Future<void> _acceptReservation(String reservationId) async {

    // Arrêter la musique quand l'admin accepte
    _stopLocalNotifications();

    try {
      // Vérifier le statut actuel de la réservation avant d'accepter
      final reservation = await _reservationService.getReservationById(reservationId);
      if (reservation == null) {
        _showStatusError('Réservation non trouvée');
        return;
      }

      // Vérifier que la réservation est toujours en attente
      if (reservation.status != ReservationStatus.pending) {
        _showStatusError('Cette réservation a déjà été traitée');
        return;
      }

      // Utiliser le callback pour faire exactement la même chose que la liste des demandes en attente
      // Cela garantit que la réservation est ajoutée à _processingReservations et gérée correctement
      _notifyReservationProcessing(reservationId);
    } catch (e) {
      _showStatusError('Erreur lors de la vérification du statut');
    }
  }

  // Refuser directement la réservation (même logique que la liste des demandes en attente)
  void _showRefusalOptions(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) {
      return;
    }


    // Vérifier le statut avant de refuser
    _checkStatusAndDecline(reservation.id);
  }

  // Vérifier le statut et refuser si possible
  Future<void> _checkStatusAndDecline(String reservationId) async {
    try {
      // Vérifier le statut actuel de la réservation avant de refuser
      final reservation = await _reservationService.getReservationById(reservationId);
      if (reservation == null) {
        _showStatusError('Réservation non trouvée');
        return;
      }

      // Vérifier que la réservation est toujours en attente
      if (reservation.status != ReservationStatus.pending) {
        _showStatusError('Cette réservation a déjà été traitée');
        return;
      }

      // Procéder au refus
      await _declineReservation(reservationId);
    } catch (e) {
      _showStatusError('Erreur lors de la vérification du statut');
    }
  }

  // Refuser une réservation (même logique que la liste des demandes en attente)
  Future<void> _declineReservation(String reservationId) async {

    // Arrêter la musique quand l'admin refuse
    _stopLocalNotifications();

    try {
      // Vérifier le statut actuel de la réservation avant de refuser
      final reservation = await _reservationService.getReservationById(reservationId);
      if (reservation == null) {
        _showStatusError('Réservation non trouvée');
        return;
      }

      // Vérifier que la réservation est toujours en attente
      if (reservation.status != ReservationStatus.pending) {
        _showStatusError('Cette réservation a déjà été traitée');
        return;
      }

      // Mettre à jour le statut de la réservation à cancelled (comme dans _refuseReservation)
      await _reservationService.updateReservationStatus(
        reservationId,
        ReservationStatus.cancelled,
      );

      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(_globalContext!).reservationRefused),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(_globalContext!).error(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Afficher le dialogue de contre-offre
  void _showCounterOfferDialog(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) return;

    // Vérifier le statut avant d'afficher le dialogue de contre-offre
    _checkStatusAndShowCounterOffer(reservation);
  }

  // Vérifier le statut et afficher le dialogue de contre-offre si possible
  Future<void> _checkStatusAndShowCounterOffer(Reservation reservation) async {
    try {
      // Vérifier le statut actuel de la réservation avant de proposer une contre-offre
      final currentReservation = await _reservationService.getReservationById(reservation.id);
      if (currentReservation == null) {
        _showStatusError('Réservation non trouvée');
        return;
      }

      // Vérifier que la réservation est toujours en attente
      if (currentReservation.status != ReservationStatus.pending) {
        _showStatusError('Cette réservation a déjà été traitée');
        return;
      }

      // Procéder à l'affichage du dialogue de contre-offre
      _showCounterOfferDialogInternal(reservation);
    } catch (e) {
      _showStatusError('Erreur lors de la vérification du statut');
    }
  }

  // Afficher le dialogue de contre-offre (méthode interne)
  void _showCounterOfferDialogInternal(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) return;

    DateTime selectedDate = reservation.selectedDate;
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(reservation.selectedTime.split(':')[0]),
      minute: int.parse(reservation.selectedTime.split(':')[1]),
    );
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: _globalContext!,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgElev,
          title: Text(
            'Proposer une nouvelle date/heure',
            style: TextStyle(color: AppColors.textStrong),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date/heure actuelle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.glass.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassStroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date/heure actuelle:',
                        style: TextStyle(
                          color: AppColors.textWeak,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reservation.selectedDate.day}/${reservation.selectedDate.month}/${reservation.selectedDate.year} à ${reservation.selectedTime}',
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nouvelle date
                Text(
                  'Nouvelle date:',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent,
                              onPrimary: Colors.white,
                              surface: AppColors.bgElev,
                              onSurface: Colors.white,
                              secondary: AppColors.accent,
                              onSecondary: Colors.white,
                            ),
                            dialogBackgroundColor: AppColors.bgElev,
                            cardColor: AppColors.bgElev,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nouvelle heure
                Text(
                  'Nouvelle heure:',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent,
                              onPrimary: Colors.white,
                              surface: AppColors.bgElev,
                              onSurface: Colors.white,
                              secondary: AppColors.accent,
                              onSecondary: Colors.white,
                            ),
                            dialogBackgroundColor: AppColors.bgElev,
                            cardColor: AppColors.bgElev,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message/commentaire
                Text(
                  'Commentaire pour le client:',
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(_globalContext!).explainScheduleChange,
                    hintStyle: TextStyle(color: AppColors.textWeak),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.glass.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textWeak),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTime =
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                Navigator.of(context).pop();
                _sendCounterOffer(
                  reservation.id,
                  selectedDate,
                  newTime,
                  messageController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(_globalContext!).propose),
            ),
          ],
        ),
      ),
    );
  }

  // Envoyer la contre-offre
  Future<void> _sendCounterOffer(
    String reservationId,
    DateTime newDate,
    String newTime,
    String message,
  ) async {
    // Arrêter la musique quand l'admin fait une contre-offre
    _stopLocalNotifications();

    try {
      // Vérifier le statut actuel de la réservation avant d'envoyer la contre-offre
      final reservation = await _reservationService.getReservationById(reservationId);
      if (reservation == null) {
        _showStatusError('Réservation non trouvée');
        return;
      }

      // Vérifier que la réservation est toujours en attente
      if (reservation.status != ReservationStatus.pending) {
        _showStatusError('Cette réservation a déjà été traitée');
        return;
      }

      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({
            'hasCounterOffer': true,
            'driverProposedDate': Timestamp.fromDate(
              DateTime.utc(newDate.year, newDate.month, newDate.day),
            ),
            'driverProposedTime': newTime,
            'adminMessage': message,
            'status': ReservationStatus.confirmed.name,
            'lastUpdated': Timestamp.now(),
          });

      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Contre-offre envoyée: ${newDate.day}/${newDate.month} à $newTime',
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(_globalContext!).error(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Méthode de débogage pour afficher l'état du service
  void debugServiceState() {
  }

  // Envoyer une notification de demande de paiement au client
  Future<void> sendPaymentRequestNotification(
    String userId,
    String reservationId,
    double amount,
  ) async {
    try {

      // Créer la notification de paiement
      final notification = {
        'id': 'payment_request_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'reservationId': reservationId,
        'type': 'payment_request',
        'title': 'Paiement requis',
        'body':
            'Veuillez effectuer le paiement de ${amount.toStringAsFixed(2)} CHF pour votre réservation',
        'amount': amount,
        'createdAt': Timestamp.now(),
        'isRead': false,
        'priority': 'high',
      };

      // Sauvegarder la notification dans Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification['id'] as String)
          .set(notification);

    } catch (e) {
      rethrow;
    }
  }

  // Callback pour notifier qu'une réservation est en cours de traitement
  static void Function(String)? _onReservationProcessing;

  static void setReservationProcessingCallback(void Function(String) callback) {
    _onReservationProcessing = callback;
  }

  void _notifyReservationProcessing(String reservationId) {
    if (_onReservationProcessing != null) {
      _onReservationProcessing!(reservationId);
    }
  }

  // Afficher une notification locale
  void _showLocalNotification({
    required String clientName,
    required String reservationId,
  }) {
    // La notification sera gérée par le BackgroundNotificationService
  }


  // Arrêter le polling en arrière-plan
  void stopBackgroundPolling() {
    _backgroundPollingTimer?.cancel();
    _backgroundPollingTimer = null;
  }

  // Redémarrer le polling en arrière-plan
  void restartBackgroundPolling() {
    _startBackgroundPolling();
  }

  // Arrêter les notifications locales (méthode publique)
  void stopLocalNotifications() {
    _stopLocalNotifications();
  }

  // Afficher un message d'erreur de statut
  void _showStatusError(String message) {
    if (_globalContext != null && _globalContext!.mounted) {
      ScaffoldMessenger.of(_globalContext!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Nettoyer les ressources
  void dispose() {
    _reservationSubscription?.cancel();
    _soundTimer?.cancel();
    _soundTimeoutTimer?.cancel();
    _backgroundPollingTimer?.cancel();
    _audioPlayer.dispose();
    _globalContext = null;
    _isInitialized = false;
    _processedReservations.clear();
    // ✅ Nettoyer aussi le tracking des réservations en cours
    _processingReservations.clear();
    _isPlaying = false;
  }
}
