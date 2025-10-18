import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/notification_service.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final ReservationService _reservationService = ReservationService();
  Timer? _currentNotificationTimer;
  Reservation? _currentNotificationReservation;
  BuildContext? _currentContext;

  // Afficher une notification avec gestion des priorités
  void showNotification(
    BuildContext context,
    Reservation reservation, {
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    VoidCallback? onCounterOffer,
  }) {
    // Si une notification est déjà affichée, la fermer
    if (_currentNotificationReservation != null) {
      _closeCurrentNotification();
    }

    // Mettre à jour le contexte et la réservation courante
    _currentContext = context;
    _currentNotificationReservation = reservation;

    // Afficher la nouvelle notification
    NotificationService.showUberStyleNotification(
      context,
      reservation,
      onAccept: () {
        _closeCurrentNotification();
        onAccept();
      },
      onDecline: () {
        _closeCurrentNotification();
        onDecline();
      },
      onCounterOffer: onCounterOffer != null
          ? () {
              _closeCurrentNotification();
              onCounterOffer();
            }
          : null,
    );

    // Démarrer le timer de 30 secondes
    _startNotificationTimer(reservation);
  }

  // Afficher une notification globale (peu importe où on est dans l'admin)
  void showGlobalNotification(
    BuildContext context,
    Reservation reservation, {
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    VoidCallback? onCounterOffer,
  }) {

    // Si une notification est déjà affichée, la fermer
    if (_currentNotificationReservation != null) {
      _closeCurrentNotification();
    }

    // Mettre à jour le contexte et la réservation courante
    _currentContext = context;
    _currentNotificationReservation = reservation;


    // Afficher la nouvelle notification
    try {
      NotificationService.showUberStyleNotification(
        context,
        reservation,
        onAccept: () {
          _closeCurrentNotification();
          onAccept();
        },
        onDecline: () {
          _closeCurrentNotification();
          onDecline();
        },
        onCounterOffer: onCounterOffer != null
            ? () {
                _closeCurrentNotification();
                onCounterOffer();
              }
            : null,
        onClose: () {
          _closeCurrentNotification();
        },
        onPending: () {
          _closeCurrentNotification();
          _handlePendingReservation(reservation);
        },
      );

      // Démarrer le timer de 30 secondes
      _startNotificationTimer(reservation);
    } catch (e) {
    }
  }

  void _startNotificationTimer(Reservation reservation) {
    _currentNotificationTimer?.cancel();
    _currentNotificationTimer = Timer(const Duration(seconds: 30), () {
      if (_currentNotificationReservation?.id == reservation.id) {
        _handleTimeout(reservation);
      } else {
      }
    });
  }

  void _handleTimeout(Reservation reservation) {
    // Timeout - mettre automatiquement en attente
    _handlePendingReservation(reservation);
  }

  Future<void> _handlePendingReservation(Reservation reservation) async {
    try {

      // Mettre la réservation en attente (statut pending mais avec un flag spécial)
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.pending,
      );


      // Ajouter un champ pour indiquer qu'elle est en attente d'action admin
      await _reservationService.updateReservationField(
        reservation.id,
        'adminPending',
        true,
      );


      await _reservationService.updateReservationField(
        reservation.id,
        'pendingAt',
        DateTime.now().toIso8601String(),
      );

      _closeCurrentNotification();

      if (_currentContext != null && _currentContext!.mounted) {
        ScaffoldMessenger.of(_currentContext!).showSnackBar(
          SnackBar(
            content: Text(
              'Réservation ${reservation.id.substring(0, 8)} mise en attente',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
    }
  }

  void _closeCurrentNotification() {
    _currentNotificationTimer?.cancel();
    _currentNotificationTimer = null;
    _currentNotificationReservation = null;
    _currentContext = null;
  }

  // Vérifier s'il y a une notification active
  bool get hasActiveNotification => _currentNotificationReservation != null;

  // Obtenir la réservation de notification active
  Reservation? get currentNotificationReservation =>
      _currentNotificationReservation;

  // Forcer la fermeture de la notification active
  void forceCloseNotification() {
    _closeCurrentNotification();
  }

  // Nettoyer les ressources
  void dispose() {
    _currentNotificationTimer?.cancel();
    _currentNotificationTimer = null;
    _currentNotificationReservation = null;
    _currentContext = null;
  }
}
