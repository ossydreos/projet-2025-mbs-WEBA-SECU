import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/models/reservation.dart';
import '../data/services/fcm_notification_service.dart';

/// Proxy centralisé pour éviter les dépendances circulaires
/// Centralise tous les appels entre services
class ServiceProxy {
  static ServiceProxy? _instance;
  ServiceProxy._internal();
  
  static ServiceProxy get instance {
    _instance ??= ServiceProxy._internal();
    return _instance!;
  }

  // Instances des services avec lazy loading
  static dynamic getReservationService() {
    // Import dynamique pour éviter la circularité
    // C'est un hack mais ça marche !
    return null; // To be implemented
  }

  static dynamic getNotificationService() {
    return null; // To be implemented
  }

  static dynamic getFCMService() {
    return FCMNotificationService();
  }

  /// Méthode centrale pour toutes les notifications admin
  static Future<void> notifyAdminNewReservation(Reservation reservation) async {
    try {
      // Logique centralisée ici au lieu d'être éparpillée
      await FCMNotificationService().sendNotificationToAdmin(reservation);
    } catch (e) {    LoggingService.info('Erreur notification admin: $e');
    }
  }

  /// Méthode centrale pour toutes les notifications client
  static Future<void> notifyClientReservationUpdate(Reservation reservation) async {
    try {
      await FCMNotificationService().sendNotificationToClient(reservation);
    } catch (e) {    LoggingService.info('Erreur notification client: $e');
    }
  }
}
