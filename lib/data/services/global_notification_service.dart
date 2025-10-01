import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/notification_manager.dart';

class GlobalNotificationService {
  static final GlobalNotificationService _instance =
      GlobalNotificationService._internal();
  factory GlobalNotificationService() => _instance;
  GlobalNotificationService._internal();

  final ReservationService _reservationService = ReservationService();
  final NotificationManager _notificationManager = NotificationManager();
  StreamSubscription<QuerySnapshot>? _reservationSubscription;
  BuildContext? _globalContext;
  DateTime _lastSeenReservationAt = DateTime.now();

  // Initialiser le service global
  void initialize(BuildContext context) {
    _globalContext = context;
    _startListeningToReservations();
  }

  // Démarrer l'écoute des nouvelles réservations
  void _startListeningToReservations() {
    _reservationSubscription = FirebaseFirestore.instance
        .collection('reservations')
        .where('status', isEqualTo: 'pending')
        .where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(_lastSeenReservationAt),
        )
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final reservation = Reservation.fromMap({...data, 'id': doc.id});

            // Vérifier si c'est une nouvelle réservation
            if (reservation.createdAt.isAfter(_lastSeenReservationAt)) {
              _showNotificationForReservation(reservation);
            }
          }

          // Mettre à jour la dernière réservation vue
          _lastSeenReservationAt = DateTime.now();
        });
  }

  // Afficher la notification pour une réservation
  void _showNotificationForReservation(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) return;

    _notificationManager.showGlobalNotification(
      _globalContext!,
      reservation,
      onAccept: () => _acceptReservation(reservation.id),
      onDecline: () => _declineReservation(reservation.id),
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
          const SnackBar(
            content: Text('Réservation acceptée'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'acceptation: $e');
    }
  }

  // Afficher les options de refus
  void _showRefusalOptions(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) return;

    showDialog(
      context: _globalContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Refuser la réservation',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Que souhaitez-vous faire ?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Annuler le refus - ne rien faire
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _declineReservation(reservation.id);
              },
              child: const Text('Refuser'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCounterOfferDialog(reservation);
              },
              child: const Text('Contre-offre'),
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
          const SnackBar(
            content: Text('Réservation refusée'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors du refus: $e');
    }
  }

  // Afficher le dialogue de contre-offre
  void _showCounterOfferDialog(Reservation reservation) {
    if (_globalContext == null || !_globalContext!.mounted) return;

    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: _globalContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Faire une contre-offre',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Nouvelle date',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Nouvelle heure',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendCounterOffer(
                  reservation.id,
                  dateController.text,
                  timeController.text,
                  messageController.text,
                );
              },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  // Envoyer la contre-offre
  Future<void> _sendCounterOffer(
    String reservationId,
    String date,
    String time,
    String message,
  ) async {
    try {
      await _reservationService.updateReservationField(
        reservationId,
        'hasCounterOffer',
        true,
      );
      await _reservationService.updateReservationField(
        reservationId,
        'driverProposedDate',
        date,
      );
      await _reservationService.updateReservationField(
        reservationId,
        'driverProposedTime',
        time,
      );
      await _reservationService.updateReservationField(
        reservationId,
        'adminMessage',
        message,
      );

      if (_globalContext != null && _globalContext!.mounted) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          const SnackBar(
            content: Text('Contre-offre envoyée'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la contre-offre: $e');
    }
  }

  // Nettoyer les ressources
  void dispose() {
    _reservationSubscription?.cancel();
    _globalContext = null;
  }
}
