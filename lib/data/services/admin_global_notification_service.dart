import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/notification_manager.dart';
import 'package:my_mobility_services/data/services/fcm_notification_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class AdminGlobalNotificationService {
  static final AdminGlobalNotificationService _instance =
      AdminGlobalNotificationService._internal();
  factory AdminGlobalNotificationService() => _instance;
  AdminGlobalNotificationService._internal();

  final ReservationService _reservationService = ReservationService();
  final NotificationManager _notificationManager = NotificationManager();
  final FCMNotificationService _fcmService = FCMNotificationService();
  StreamSubscription<QuerySnapshot>? _reservationSubscription;
  BuildContext? _globalContext;
  DateTime _lastSeenReservationAt = DateTime.now().subtract(
    const Duration(minutes: 5),
  );
  bool _isInitialized = false;
  Map<String, dynamic>? _pendingNotification;
  Set<String> _processedReservations = <String>{};

  // Initialiser le service global pour l'admin
  void initialize(BuildContext context) {
    _globalContext = context;
    print('🔔 AdminGlobalNotificationService: Initialisation avec contexte');
    print(
      '🔔 AdminGlobalNotificationService: Contexte monté: ${context.mounted}',
    );

    if (!_isInitialized) {
      _isInitialized = true;
      print(
        '🔔 AdminGlobalNotificationService: Démarrage de l\'écoute des réservations',
      );
      _startListeningToReservations();
    } else {
      print(
        '🔔 AdminGlobalNotificationService: Service déjà initialisé, mise à jour du contexte uniquement',
      );
    }

    // Vérifier immédiatement les réservations en attente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkPendingReservations();
    });
  }

  // Initialiser le service sans contexte (pour le démarrage global)
  void initializeGlobal() {
    if (!_isInitialized) {
      _isInitialized = true;
      print(
        '🔔 AdminGlobalNotificationService: Initialisation globale sans contexte',
      );
      // Réinitialiser le timestamp pour capturer toutes les nouvelles réservations
      _lastSeenReservationAt = DateTime.now().subtract(
        const Duration(minutes: 1),
      );
      _processedReservations.clear();
      _startListeningToReservations();
    }
  }

  // Mettre à jour le contexte (nécessaire lors des changements de page)
  void updateContext(BuildContext context) {
    _globalContext = context;
    print('🔔 AdminGlobalNotificationService: Contexte mis à jour');

    // Afficher la notification en attente si elle existe
    if (_pendingNotification != null) {
      print(
        '🔔 AdminGlobalNotificationService: Affichage de la notification en attente',
      );
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
    print(
      '🔔 AdminGlobalNotificationService: Vérification forcée des nouvelles réservations',
    );
    _lastSeenReservationAt = DateTime.now().subtract(
      const Duration(minutes: 10),
    );
    _processedReservations.clear();
  }

  // Vérifier et afficher toutes les réservations en attente manquées
  Future<void> checkPendingReservations() async {
    if (_globalContext == null || !_globalContext!.mounted) {
      print(
        '🔔 AdminGlobalNotificationService: Contexte non disponible pour vérifier les réservations',
      );
      return;
    }

    try {
      print(
        '🔔 AdminGlobalNotificationService: Vérification des réservations en attente',
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final reservationId = doc.id;

        // Vérifier si cette réservation a déjà été traitée
        if (_processedReservations.contains(reservationId)) {
          continue;
        }

        final createdAt = (data['createdAt'] as Timestamp).toDate();

        // Afficher les réservations créées dans les 10 dernières minutes
        if (createdAt.isAfter(
          DateTime.now().subtract(const Duration(minutes: 10)),
        )) {
          print(
            '🔔 AdminGlobalNotificationService: Réservation en attente trouvée: $reservationId',
          );
          _processedReservations.add(reservationId);
          _showNotificationForReservation(data);
        }
      }
    } catch (e) {
      print(
        '🔔 AdminGlobalNotificationService: Erreur lors de la vérification: $e',
      );
    }
  }

  // Forcer l'affichage d'une notification (pour les tests)
  void forceShowNotification(Reservation reservation, {BuildContext? context}) {
    print(
      '🔔 AdminGlobalNotificationService: Forçage de l\'affichage de la notification',
    );
    print('🔔 AdminGlobalNotificationService: Réservation: ${reservation.id}');
    print(
      '🔔 AdminGlobalNotificationService: Contexte fourni: ${context != null}',
    );
    print(
      '🔔 AdminGlobalNotificationService: Contexte global: ${_globalContext != null}',
    );

    // Utiliser le contexte fourni ou le contexte global
    final contextToUse = context ?? _globalContext;

    if (contextToUse == null) {
      print(
        '🔔 AdminGlobalNotificationService: ERREUR - Aucun contexte disponible pour le forçage',
      );
      return;
    }

    if (!contextToUse.mounted) {
      print('🔔 AdminGlobalNotificationService: ERREUR - Contexte non monté');
      return;
    }

    print(
      '🔔 AdminGlobalNotificationService: Contexte OK, affichage de la notification via NotificationManager',
    );

    try {
      _notificationManager.showGlobalNotification(
        contextToUse,
        reservation,
        onAccept: () => _acceptReservation(reservation.id),
        onDecline: () => _showRefusalOptions(reservation),
        onCounterOffer: () => _showCounterOfferDialog(reservation),
      );
      print(
        '🔔 AdminGlobalNotificationService: NotificationManager appelé avec succès',
      );
    } catch (e) {
      print(
        '🔔 AdminGlobalNotificationService: ERREUR lors de l\'appel au NotificationManager: $e',
      );
    }
  }

  // Démarrer l'écoute des nouvelles réservations
  void _startListeningToReservations() {
    _reservationSubscription?.cancel();

    print(
      '🔔 AdminGlobalNotificationService: Démarrage de l\'écoute des réservations',
    );
    print(
      '🔔 AdminGlobalNotificationService: Contexte disponible: ${_globalContext != null}',
    );

    _reservationSubscription = FirebaseFirestore.instance
        .collection('reservations')
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            print(
              '🔔 AdminGlobalNotificationService: ${snapshot.docChanges.length} changements détectés',
            );

            for (final change in snapshot.docChanges) {
              print(
                '🔔 AdminGlobalNotificationService: Type de changement: ${change.type}',
              );

              if (change.type != DocumentChangeType.added) {
                print(
                  '🔔 AdminGlobalNotificationService: Changement de type ${change.type}, ignoré',
                );
                continue;
              }

              final data = change.doc.data() as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              final status = data['status'] as String?;

              print(
                '🔔 AdminGlobalNotificationService: Nouvelle réservation détectée - Status: $status, Créée: $createdAt',
              );
              print(
                '🔔 AdminGlobalNotificationService: Dernière réservation vue: $_lastSeenReservationAt',
              );

              // Ne traiter que les nouvelles réservations en attente
              if (status != null && status == ReservationStatus.pending.name) {
                final reservationId = change.doc.id;

                // Vérifier si cette réservation a déjà été traitée
                if (_processedReservations.contains(reservationId)) {
                  print(
                    '🔔 AdminGlobalNotificationService: Réservation $reservationId déjà traitée, ignorée',
                  );
                  continue;
                }

                print(
                  '🔔 AdminGlobalNotificationService: Réservation en attente détectée - ID: $reservationId',
                );

                // Vérifier si c'est une nouvelle réservation (créée après la dernière vue)
                // Réduire la marge à 1 seconde pour être plus réactif
                final timeDifference = createdAt
                    .difference(_lastSeenReservationAt)
                    .inSeconds;

                print(
                  '🔔 AdminGlobalNotificationService: Différence de temps: ${timeDifference}s',
                );

                // Accepter les réservations créées dans les 5 dernières minutes ou plus récentes
                if (timeDifference > 1 ||
                    createdAt.isAfter(
                      DateTime.now().subtract(const Duration(minutes: 5)),
                    )) {
                  print(
                    '🔔 AdminGlobalNotificationService: Nouvelle réservation détectée (diff: ${timeDifference}s), affichage de la notification',
                  );

                  // Marquer comme traitée pour éviter les doublons
                  _processedReservations.add(reservationId);

                  // Mettre à jour le timestamp seulement si c'est vraiment plus récent
                  if (createdAt.isAfter(_lastSeenReservationAt)) {
                    _lastSeenReservationAt = createdAt;
                  }

                  _showNotificationForReservation(data);
                } else {
                  print(
                    '🔔 AdminGlobalNotificationService: Réservation trop ancienne (diff: ${timeDifference}s), ignorée',
                  );
                }
              } else {
                print(
                  '🔔 AdminGlobalNotificationService: Réservation avec status $status, ignorée',
                );
              }
            }
          },
          onError: (error) {
            print(
              '🔔 AdminGlobalNotificationService: Erreur lors de l\'écoute: $error',
            );
          },
        );
  }

  // Afficher la notification pour une réservation
  void _showNotificationForReservation(Map<String, dynamic> data) {
    print(
      '🔔 AdminGlobalNotificationService: Tentative d\'affichage de notification',
    );
    print(
      '🔔 AdminGlobalNotificationService: Contexte disponible: ${_globalContext != null}',
    );
    print(
      '🔔 AdminGlobalNotificationService: Contexte monté: ${_globalContext?.mounted ?? false}',
    );

    if (_globalContext == null || !_globalContext!.mounted) {
      print(
        '🔔 AdminGlobalNotificationService: Contexte non disponible, notification mise en attente',
      );
      // Stocker la notification en attente pour l'afficher quand le contexte sera disponible
      _pendingNotification = data;
      return;
    }

    print(
      '🔔 AdminGlobalNotificationService: Affichage de la notification pour la réservation',
    );

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

    print(
      '🔔 AdminGlobalNotificationService: Réservation créée - ${reservation.userName} de ${reservation.departure} vers ${reservation.destination}',
    );

    try {
      // Démarrer la notification FCM Uber style
      _fcmService.startUberStyleNotification(
        clientName: reservation.userName ?? 'Client',
        reservationId: reservation.id,
      );

      _notificationManager.showGlobalNotification(
        _globalContext!,
        reservation,
        onAccept: () {
          // Arrêter la notification quand l'admin répond
          _fcmService.stopNotification();
          _acceptReservation(reservation.id);
        },
        onDecline: () {
          // Arrêter la notification quand l'admin répond
          _fcmService.stopNotification();
          _showRefusalOptions(reservation);
        },
        onCounterOffer: () {
          // Arrêter la notification quand l'admin répond
          _fcmService.stopNotification();
          _showCounterOfferDialog(reservation);
        },
      );

      print(
        '🔔 AdminGlobalNotificationService: Notification affichée avec succès pour ${reservation.userName}',
      );
    } catch (e) {
      print(
        '🔔 AdminGlobalNotificationService: Erreur lors de l\'affichage de la notification: $e',
      );

      // Fallback: afficher une notification simple si le système principal échoue
      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text(
              '🔔 Nouvelle réservation de ${reservation.userName} de ${reservation.departure} vers ${reservation.destination}',
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // Optionnel: naviguer vers la page de gestion des réservations
                print(
                  '🔔 Action "Voir" cliquée pour la réservation ${reservation.id}',
                );
              },
            ),
          ),
        );
      }
    }
  }

  // Accepter une réservation (délègue à l'écran de réception pour la même logique)
  Future<void> _acceptReservation(String reservationId) async {
    print(
      '🔔 AdminGlobalNotificationService: Acceptation de la réservation $reservationId',
    );

    // Utiliser le callback pour faire exactement la même chose que la liste des demandes en attente
    // Cela garantit que la réservation est ajoutée à _processingReservations et gérée correctement
    _notifyReservationProcessing(reservationId);
  }

  // Refuser directement la réservation (même logique que la liste des demandes en attente)
  void _showRefusalOptions(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) {
      print(
        '❌ AdminGlobalNotificationService: Contexte non disponible pour refuser',
      );
      return;
    }

    print(
      '🔔 AdminGlobalNotificationService: Refus direct de la réservation ${reservation.id}',
    );

    // Refuser directement sans menu (comme dans la liste des demandes en attente)
    _declineReservation(reservation.id);
  }

  // Refuser une réservation (même logique que la liste des demandes en attente)
  Future<void> _declineReservation(String reservationId) async {
    print(
      '🔔 AdminGlobalNotificationService: Refus de la réservation $reservationId',
    );

    try {
      // Mettre à jour le statut de la réservation à cancelled (comme dans _refuseReservation)
      await _reservationService.updateReservationStatus(
        reservationId,
        ReservationStatus.cancelled,
      );

      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text('Réservation refusée'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      print(
        '✅ AdminGlobalNotificationService: Réservation refusée avec succès',
      );
    } catch (e) {
      print('❌ AdminGlobalNotificationService: Erreur lors du refus: $e');
      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
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
                    hintText: 'Expliquez le motif du changement d\'horaire...',
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
              child: const Text('Proposer'),
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
    try {
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
      print('Erreur lors de l\'envoi de la contre-offre: $e');
      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Méthode de débogage pour afficher l'état du service
  void debugServiceState() {
    print('🔔 AdminGlobalNotificationService: État du service');
    print('  - Initialisé: $_isInitialized');
    print('  - Contexte disponible: ${_globalContext != null}');
    print('  - Contexte monté: ${_globalContext?.mounted ?? false}');
    print('  - Réservations traitées: ${_processedReservations.length}');
    print('  - Dernière réservation vue: $_lastSeenReservationAt');
    print('  - Notification en attente: ${_pendingNotification != null}');
  }

  // Envoyer une notification de demande de paiement au client
  Future<void> sendPaymentRequestNotification(
    String userId,
    String reservationId,
    double amount,
  ) async {
    try {
      print(
        '💳 Envoi de la demande de paiement pour la réservation $reservationId',
      );

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

      print('✅ Notification de paiement envoyée avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la notification de paiement: $e');
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

  // Nettoyer les ressources
  void dispose() {
    _reservationSubscription?.cancel();
    _fcmService.dispose();
    _globalContext = null;
    _isInitialized = false;
    _processedReservations.clear();
  }
}
