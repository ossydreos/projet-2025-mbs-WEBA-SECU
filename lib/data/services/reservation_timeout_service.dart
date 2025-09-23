import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';

class ReservationTimeoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReservationService _reservationService = ReservationService();
  
  Timer? _timeoutTimer;
  static const Duration _timeoutDuration = Duration(minutes: 30);
  
  // Démarrer le service de timeout
  void startTimeoutService() {
    print('🕐 Démarrage du service de timeout des réservations');
    
    // Vérifier toutes les 5 minutes
    _timeoutTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndTimeoutReservations();
    });
    
    // Vérifier immédiatement au démarrage
    _checkAndTimeoutReservations();
  }
  
  // Arrêter le service de timeout
  void stopTimeoutService() {
    print('🛑 Arrêt du service de timeout des réservations');
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
  
  // Vérifier et refuser les réservations en timeout
  Future<void> _checkAndTimeoutReservations() async {
    try {
      print('🔍 Vérification des réservations en timeout...');
      
      final now = DateTime.now();
      final timeoutThreshold = now.subtract(_timeoutDuration);
      
      // Récupérer les réservations en attente depuis plus de 30 minutes
      final querySnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .where('createdAt', isLessThan: Timestamp.fromDate(timeoutThreshold))
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('✅ Aucune réservation en timeout trouvée');
        return;
      }
      
      print('⚠️ ${querySnapshot.docs.length} réservation(s) en timeout trouvée(s)');
      
      // Traiter chaque réservation en timeout
      for (final doc in querySnapshot.docs) {
        try {
          final reservationData = doc.data();
          final reservationId = doc.id;
          final createdAt = (reservationData['createdAt'] as Timestamp).toDate();
          
          print('⏰ Timeout réservation $reservationId créée à ${createdAt.toIso8601String()}');
          
          // Refuser la réservation avec notification
          await _reservationService.refuseReservation(
            reservationId,
            reason: 'Demande automatiquement refusée après 30 minutes d\'attente',
          );
          
          print('✅ Réservation $reservationId refusée automatiquement');
          
        } catch (e) {
          print('❌ Erreur lors du refus automatique de la réservation ${doc.id}: $e');
        }
      }
      
    } catch (e) {
      print('❌ Erreur lors de la vérification des timeouts: $e');
    }
  }
  
  // Vérifier une réservation spécifique
  Future<bool> checkReservationTimeout(String reservationId) async {
    try {
      final doc = await _firestore.collection('reservations').doc(reservationId).get();
      
      if (!doc.exists) {
        return false;
      }
      
      final data = doc.data()!;
      final status = data['status'] as String;
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      
      // Vérifier si la réservation est en attente depuis plus de 30 minutes
      if (status == ReservationStatus.pending.name) {
        final now = DateTime.now();
        final timeSinceCreation = now.difference(createdAt);
        
        if (timeSinceCreation >= _timeoutDuration) {
          print('⏰ Réservation $reservationId en timeout depuis ${timeSinceCreation.inMinutes} minutes');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur lors de la vérification du timeout de la réservation $reservationId: $e');
      return false;
    }
  }
  
  // Refuser une réservation en timeout
  Future<void> timeoutReservation(String reservationId) async {
    try {
      await _reservationService.refuseReservation(
        reservationId,
        reason: 'Demande automatiquement refusée après 30 minutes d\'attente',
      );
      
      print('✅ Réservation $reservationId refusée automatiquement pour timeout');
    } catch (e) {
      print('❌ Erreur lors du refus automatique de la réservation $reservationId: $e');
    }
  }
  
  // Obtenir le temps restant avant timeout pour une réservation
  Future<Duration?> getTimeUntilTimeout(String reservationId) async {
    try {
      final doc = await _firestore.collection('reservations').doc(reservationId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      final status = data['status'] as String;
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      
      if (status != ReservationStatus.pending.name) {
        return null;
      }
      
      final now = DateTime.now();
      final timeSinceCreation = now.difference(createdAt);
      final timeUntilTimeout = _timeoutDuration - timeSinceCreation;
      
      return timeUntilTimeout.isNegative ? Duration.zero : timeUntilTimeout;
    } catch (e) {
      print('❌ Erreur lors du calcul du temps restant pour la réservation $reservationId: $e');
      return null;
    }
  }
  
  // Obtenir toutes les réservations proches du timeout (moins de 5 minutes)
  Future<List<Map<String, dynamic>>> getReservationsNearTimeout() async {
    try {
      final now = DateTime.now();
      final warningThreshold = now.subtract(_timeoutDuration - const Duration(minutes: 5));
      final timeoutThreshold = now.subtract(_timeoutDuration);
      
      final querySnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .where('createdAt', isLessThan: Timestamp.fromDate(warningThreshold))
          .where('createdAt', isGreaterThan: Timestamp.fromDate(timeoutThreshold))
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des réservations proches du timeout: $e');
      return [];
    }
  }
  
  // Obtenir toutes les réservations en timeout
  Future<List<Map<String, dynamic>>> getTimedOutReservations() async {
    try {
      final now = DateTime.now();
      final timeoutThreshold = now.subtract(_timeoutDuration);
      
      final querySnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.pending.name)
          .where('createdAt', isLessThan: Timestamp.fromDate(timeoutThreshold))
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des réservations en timeout: $e');
      return [];
    }
  }
}
