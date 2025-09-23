import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/notification_manager.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class AdminGlobalNotificationService {
  static final AdminGlobalNotificationService _instance =
      AdminGlobalNotificationService._internal();
  factory AdminGlobalNotificationService() => _instance;
  AdminGlobalNotificationService._internal();

  final ReservationService _reservationService = ReservationService();
  final NotificationManager _notificationManager = NotificationManager();
  StreamSubscription<QuerySnapshot>? _reservationSubscription;
  BuildContext? _globalContext;
  DateTime _lastSeenReservationAt = DateTime.now();
  bool _isInitialized = false;

  // Initialiser le service global pour l'admin
  void initialize(BuildContext context) {
    _globalContext = context;
    if (!_isInitialized) {
      _isInitialized = true;
      _startListeningToReservations();
    }
  }

  // Mettre à jour le contexte (nécessaire lors des changements de page)
  void updateContext(BuildContext context) {
    _globalContext = context;
  }

  // Forcer l'affichage d'une notification (pour les tests)
  void forceShowNotification(Reservation reservation) {
    print(
      '🔔 AdminGlobalNotificationService: Forçage de l\'affichage de la notification',
    );

    if (_globalContext == null || !_globalContext!.mounted) {
      print(
        '🔔 AdminGlobalNotificationService: Contexte non disponible pour le forçage',
      );
      return;
    }

    print(
      '🔔 AdminGlobalNotificationService: Affichage de la notification via NotificationManager',
    );

    _notificationManager.showGlobalNotification(
      _globalContext!,
      reservation,
      onAccept: () => _acceptReservation(reservation.id),
      onDecline: () => _showRefusalOptions(reservation),
      onCounterOffer: () => _showCounterOfferDialog(reservation),
    );
  }

  // Démarrer l'écoute des nouvelles réservations
  void _startListeningToReservations() {
    _reservationSubscription?.cancel();

    print(
      '🔔 AdminGlobalNotificationService: Démarrage de l\'écoute des réservations',
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
                // Vérifier si c'est une nouvelle réservation (créée après la dernière vue)
                // Ajouter une marge de 5 secondes pour éviter les problèmes de timing
                final timeDifference = createdAt
                    .difference(_lastSeenReservationAt)
                    .inSeconds;

                if (timeDifference > 5) {
                  print(
                    '🔔 AdminGlobalNotificationService: Réservation plus récente que la dernière vue (diff: ${timeDifference}s), affichage de la notification',
                  );
                  _lastSeenReservationAt = createdAt;
                  _showNotificationForReservation(data);
                } else {
                  print(
                    '🔔 AdminGlobalNotificationService: Réservation trop récente (diff: ${timeDifference}s), ignorée pour éviter les doublons',
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
    if (_globalContext == null || !_globalContext!.mounted) {
      print(
        '🔔 AdminGlobalNotificationService: Contexte non disponible, notification ignorée',
      );
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

    _notificationManager.showGlobalNotification(
      _globalContext!,
      reservation,
      onAccept: () => _acceptReservation(reservation.id),
      onDecline: () => _showRefusalOptions(reservation),
      onCounterOffer: () => _showCounterOfferDialog(reservation),
    );
  }

  // Accepter une réservation
  Future<void> _acceptReservation(String reservationId) async {
    try {
      await _reservationService.updateReservationStatus(
        reservationId,
        ReservationStatus.confirmed,
      );

      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: const Text('Réservation acceptée !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'acceptation: $e');
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

  // Afficher les options de refus
  void _showRefusalOptions(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) return;

    showDialog(
      context: _globalContext!,
      builder: (BuildContext context) {
        return GlassActionDialog(
          title: 'Action sur la réservation',
          message: 'Que souhaitez-vous faire avec cette réservation ?',
          actions: [
            GlassActionButton(
              label: 'Annuler',
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.textWeak,
            ),
            GlassActionButton(
              label: 'Refuser',
              onPressed: () {
                Navigator.of(context).pop();
                _declineReservation(reservation.id);
              },
              icon: Icons.close,
              color: Colors.red,
            ),
            GlassActionButton(
              label: 'Contre-offre',
              onPressed: () {
                Navigator.of(context).pop();
                _showCounterOfferDialog(reservation);
              },
              icon: Icons.handshake,
              color: AppColors.accent,
              isPrimary: true,
            ),
          ],
        );
      },
    );
  }

  // Refuser une réservation
  Future<void> _declineReservation(String reservationId) async {
    try {
      await _reservationService.updateReservationStatus(
        reservationId,
        ReservationStatus.cancelled,
      );

      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: const Text('Réservation refusée'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors du refus: $e');
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

  // Nettoyer les ressources
  void dispose() {
    _reservationSubscription?.cancel();
    _globalContext = null;
    _isInitialized = false;
  }
}
