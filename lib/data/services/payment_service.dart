import 'dart:developer' as developer;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../../firebase/api_keys_service.dart';

class PaymentService {
  // Clé publique Stripe - SÉCURISÉE via Firebase Functions
  static Future<String> get _stripePublishableKey async => 
      await ApiKeysService.getStripePublishableKey();
  // Clé secrète Stripe - SÉCURISÉE via Firebase Functions
  static Future<String> get _stripeSecretKey async => 
      await ApiKeysService.getStripeSecretKey();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialiser Stripe (optionnel)
  static Future<void> initializeStripe() async {
    try {
      Stripe.publishableKey = await _stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      // Continuer sans Stripe
    }
  }

  // Créer un PaymentIntent sur le serveur (à implémenter côté backend)
  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    required String reservationId,
  }) async {
    try {
      // TODO: Remplacer par votre endpoint backend
      final response = await http.post(
        Uri.parse('https://your-backend.com/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _stripeSecretKey}',
        },
        body: jsonEncode({
          'amount': (amount * 100).round(), // Stripe utilise les centimes
          'currency': currency,
          'metadata': {'reservation_id': reservationId},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la création du PaymentIntent');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error creating payment intent',
        name: 'PaymentService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de créer l\'intention de paiement');
    }
  }

  // Processus de paiement complet (version simplifiée)
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String reservationId,
    required String paymentMethodId,
  }) async {
    try {
      // Pour l'instant, simuler un paiement réussi
      // TODO: Implémenter le vrai paiement Stripe

      await Future.delayed(const Duration(seconds: 2)); // Simulation

      // Mettre à jour la réservation dans Firestore
      await _updateReservationPaymentStatus(
        reservationId: reservationId,
        paymentIntentId:
            'pi_simulated_${DateTime.now().millisecondsSinceEpoch}',
        status: 'paid',
      );

      return PaymentResult.success(
        paymentIntentId:
            'pi_simulated_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
      );
    } catch (e) {
      return PaymentResult.failed(error: 'Erreur inattendue: $e');
    }
  }

  // Paiement avec Apple Pay (version simplifiée)
  Future<PaymentResult> processApplePayPayment({
    required double amount,
    required String currency,
    required String reservationId,
  }) async {
    try {
      // Pour l'instant, simuler un paiement Apple Pay réussi
      await Future.delayed(const Duration(seconds: 2)); // Simulation

      await _updateReservationPaymentStatus(
        reservationId: reservationId,
        paymentIntentId: 'pi_apple_${DateTime.now().millisecondsSinceEpoch}',
        status: 'paid',
      );

      return PaymentResult.success(
        paymentIntentId: 'pi_apple_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
      );
    } catch (e) {
      return PaymentResult.failed(error: 'Erreur Apple Pay: $e');
    }
  }

  // Paiement avec Google Pay (version simplifiée)
  Future<PaymentResult> processGooglePayPayment({
    required double amount,
    required String currency,
    required String reservationId,
  }) async {
    try {
      // Pour l'instant, simuler un paiement Google Pay réussi
      await Future.delayed(const Duration(seconds: 2)); // Simulation

      await _updateReservationPaymentStatus(
        reservationId: reservationId,
        paymentIntentId: 'pi_google_${DateTime.now().millisecondsSinceEpoch}',
        status: 'paid',
      );

      return PaymentResult.success(
        paymentIntentId: 'pi_google_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
      );
    } catch (e) {
      return PaymentResult.failed(error: 'Erreur Google Pay: $e');
    }
  }

  // Mettre à jour le statut de paiement dans Firestore
  Future<void> _updateReservationPaymentStatus({
    required String reservationId,
    required String paymentIntentId,
    required String status,
  }) async {
    await _firestore.collection('reservations').doc(reservationId).update({
      'paymentStatus': status,
      'paymentIntentId': paymentIntentId,
      'paymentCompletedAt': Timestamp.now(),
      'status': ReservationStatus.confirmed.name,
      'isPaid': true, // Marquer comme payé
      'lastUpdated': Timestamp.now(),
    });

    // Notifier que le paiement est terminé (pour retirer de l'état de traitement)
    _notifyPaymentCompleted(reservationId);
  }

  // Callback pour notifier la completion du paiement
  static void Function(String)? _onPaymentCompleted;

  static void setPaymentCompletedCallback(void Function(String) callback) {
    _onPaymentCompleted = callback;
  }

  void _notifyPaymentCompleted(String reservationId) {
    if (_onPaymentCompleted != null) {
      _onPaymentCompleted!(reservationId);
    }
  }

  // Remboursement
  Future<PaymentResult> processRefund({
    required String paymentIntentId,
    required double amount,
    required String reason,
  }) async {
    try {
      // TODO: Implémenter le remboursement côté backend
      await Future.delayed(const Duration(seconds: 1)); // Simulation

      return PaymentResult.success(
        paymentIntentId: 'refund_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: 'EUR',
      );
    } catch (e) {
      return PaymentResult.failed(error: 'Erreur remboursement: $e');
    }
  }

  // Vérifier le statut d'un paiement
  Future<PaymentStatus> getPaymentStatus(String paymentIntentId) async {
    try {
      // TODO: Implémenter la vérification côté backend
      await Future.delayed(const Duration(seconds: 1)); // Simulation

      return PaymentStatus(
        id: paymentIntentId,
        status: 'succeeded',
        amount: 25.0,
        currency: 'EUR',
        createdAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error checking payment status',
        name: 'PaymentService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de vérifier le paiement');
    }
  }
}

// Classes de résultat
class PaymentResult {
  final bool isSuccess;
  final String? paymentIntentId;
  final double? amount;
  final String? currency;
  final String? error;
  final String? errorCode;

  PaymentResult._({
    required this.isSuccess,
    this.paymentIntentId,
    this.amount,
    this.currency,
    this.error,
    this.errorCode,
  });

  factory PaymentResult.success({
    required String paymentIntentId,
    required double amount,
    required String currency,
  }) {
    return PaymentResult._(
      isSuccess: true,
      paymentIntentId: paymentIntentId,
      amount: amount,
      currency: currency,
    );
  }

  factory PaymentResult.failed({required String error, String? errorCode}) {
    return PaymentResult._(
      isSuccess: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

class PaymentStatus {
  final String id;
  final String status;
  final double amount;
  final String currency;
  final DateTime createdAt;

  PaymentStatus({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      id: json['id'],
      status: json['status'],
      amount: json['amount'] / 100.0, // Convertir des centimes
      currency: json['currency'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created'] * 1000),
    );
  }
}
