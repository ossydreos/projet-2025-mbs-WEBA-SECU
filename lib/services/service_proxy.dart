import '../data/models/reservation.dart';
import '../data/services/admin_global_notification_service.dart';
import '../data/services/client_notification_service.dart';
import '../utils/logging_service.dart';

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
    return AdminGlobalNotificationService();
  }

  static dynamic getClientNotificationService() {
    return ClientNotificationService();
  }

  /// Méthode centrale pour toutes les notifications admin
  static Future<void> notifyAdminNewReservation(Reservation reservation) async {
    try {
      // Utiliser le service admin global pour les notifications
      final adminService = AdminGlobalNotificationService();
      adminService.forceShowNotification(reservation);
    } catch (e) {
      LoggingService.info('Erreur notification admin: $e');
    }
  }

  /// Méthode centrale pour toutes les notifications client
  static Future<void> notifyClientReservationUpdate(
    Reservation reservation,
  ) async {
    try {
      final clientService = ClientNotificationService();
      await clientService.notifyReservationStatusChanged(
        userId: reservation.userId,
        reservationId: reservation.id,
        oldStatus: ReservationStatus.pending,
        newStatus: reservation.status,
      );
    } catch (e) {
      LoggingService.info('Erreur notification client: $e');
    }
  }
}
