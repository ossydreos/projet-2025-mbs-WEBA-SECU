import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';
import '../../firebase/api_keys_service.dart';

class StripeCheckoutService {
  // Clés Stripe - SÉCURISÉES via Firebase Functions
  static Future<String> get _stripePublishableKey async => 
      await ApiKeysService.getStripePublishableKey();
  static Future<String> get _stripeSecretKey async => 
      await ApiKeysService.getStripeSecretKey();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Initialiser Stripe
  static Future<void> initializeStripe() async {
    try {
      Stripe.publishableKey = await _stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE : Paiement intégré sans redirection
  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String reservationId,
    required String vehicleName,
    required String departure,
    required String destination,
  }) async {
    try {
      // 1. Créer un PaymentIntent
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        reservationId: reservationId,
        vehicleName: vehicleName,
        departure: departure,
        destination: destination,
      );

      // 2. Confirmer le paiement avec Stripe Elements (intégré)
      final paymentResult = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: null,
      );

      final resultingStatus = await _handleSuccessfulPayment(
        reservationId: reservationId,
        paymentIntentId: paymentResult.id,
        amount: amount,
        currency: currency,
      );

      return {
        'success': resultingStatus != ReservationStatus.cancelled.name,
        'paymentIntentId': paymentResult.id,
        'status': paymentResult.status,
        'reservationStatus': resultingStatus,
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du paiement: $e',
      };
    }
  }

  // ✅ Créer un PaymentIntent avec Twint
  static Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    required String reservationId,
    required String vehicleName,
    required String departure,
    required String destination,
  }) async {
    final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

    final body = {
      'amount': (amount * 100).toInt().toString(), // Stripe utilise les centimes
      'currency': currency.toLowerCase(),
      'metadata[reservation_id]': reservationId,
      'metadata[vehicle_name]': vehicleName,
      'metadata[departure]': departure,
      'metadata[destination]': destination,
      // ✅ Utiliser automatic_payment_methods (plus simple et moderne)
      'automatic_payment_methods[enabled]': 'true',
      'automatic_payment_methods[allow_redirects]': 'never',
      // ✅ Configuration pour la sécurité
      'payment_method_options[card][request_three_d_secure]': 'automatic',
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${await _stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur Stripe PaymentIntent: ${response.statusCode} - ${response.body}');
    }
  }

  // ✅ Créer un lien de paiement Stripe Checkout (qui ouvrait Chrome)
  static Future<void> createCheckoutSession({
    required double amount,
    required String currency,
    required String reservationId,
    required String vehicleName,
    required String departure,
    required String destination,
  }) async {
    try {
      // ✅ Créer une vraie session Stripe Checkout
      final session = await _createStripeSession(
        amount: amount,
        currency: currency,
        reservationId: reservationId,
        vehicleName: vehicleName,
        departure: departure,
        destination: destination,
      );
      
      // ✅ Ouvrir la session dans le navigateur
      if (await canLaunchUrl(Uri.parse(session['url']))) {
        await launchUrl(
          Uri.parse(session['url']),
          mode: LaunchMode.externalApplication,
        );
        
        // ✅ Démarrer la vérification du paiement en arrière-plan
        _startPaymentVerification(reservationId, session['id']);
      } else {
        throw Exception('Impossible d\'ouvrir le lien de paiement');
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error creating checkout session',
        name: 'StripeCheckoutService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Impossible de créer la session de paiement');
    }
  }

  // ✅ Vérifier le statut du paiement en arrière-plan
  static Future<void> _startPaymentVerification(String reservationId, String sessionId) async {
    // Vérifier plus fréquemment pour une mise à jour plus rapide
    Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        final session = await _getStripeSession(sessionId);
        final paymentStatus = session['payment_status'];
        final sessionStatus = session['status'];
        if (paymentStatus == 'paid' || sessionStatus == 'complete') {
          // ✅ Paiement confirmé, mettre à jour la base de données
          final resultingStatus = await _handleSuccessfulPayment(
            reservationId: reservationId,
            paymentIntentId: session['payment_intent'],
            amount: (session['amount_total'] / 100).toDouble(),
            currency: session['currency'],
          );
          if (resultingStatus == ReservationStatus.confirmed.name) {
            final firestore = FirebaseFirestore.instance;
            await firestore.collection('reservations').doc(reservationId).update({
              'status': ReservationStatus.inProgress.name,
              'lastUpdated': Timestamp.now(),
            });
            await _markCustomOfferAsPaid(reservationId, promoteToInProgress: true);
          }
          timer.cancel(); // Arrêter la vérification
        } else if (session['payment_status'] == 'unpaid' && 
                   DateTime.now().millisecondsSinceEpoch - session['created'] * 1000 > 300000) {
          // Timeout après 5 minutes
          timer.cancel();
        }
      } catch (e) {
      }
    });
  }

  // ✅ Récupérer les détails d'une session Stripe
  static Future<Map<String, dynamic>> _getStripeSession(String sessionId) async {
    final url = Uri.parse('https://api.stripe.com/v1/checkout/sessions/$sessionId');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${await _stripeSecretKey}',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur récupération session: ${response.statusCode}');
    }
  }

  // ✅ Finaliser à partir d'un deep link (session_id et reservation_id)
  static Future<String?> finalizePaymentFromDeepLink({
    required String sessionId,
    required String reservationId,
  }) async {
    try {
      final session = await _getStripeSession(sessionId);
      final paymentStatus = session['payment_status'];
      final sessionStatus = session['status'];
      String? resultingStatus;
      if (paymentStatus == 'paid' || sessionStatus == 'complete') {
        resultingStatus = await _handleSuccessfulPayment(
          reservationId: reservationId,
          paymentIntentId: session['payment_intent'],
          amount: (session['amount_total'] / 100).toDouble(),
          currency: session['currency'],
        );
        if (resultingStatus == ReservationStatus.confirmed.name) {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('reservations').doc(reservationId).update({
            'status': ReservationStatus.inProgress.name,
            'lastUpdated': Timestamp.now(),
          });
          await _markCustomOfferAsPaid(reservationId, promoteToInProgress: true);
        }
      }
      return resultingStatus;
    } catch (e) {
      return null;
    }
  }

  // ✅ Créer une session Stripe via l'API avec personnalisation
  static Future<Map<String, dynamic>> _createStripeSession({
    required double amount,
    required String currency,
    required String reservationId,
    required String vehicleName,
    required String departure,
    required String destination,
  }) async {
    final url = Uri.parse('https://api.stripe.com/v1/checkout/sessions');
    final body = {
      'payment_method_types[0]': 'card',
      'payment_method_types[1]': 'twint',
      'line_items[0][price_data][currency]': currency.toLowerCase(),
      'line_items[0][price_data][product_data][name]': 'Réservation $vehicleName',
      'line_items[0][price_data][product_data][description]': 'De $departure vers $destination',
      'line_items[0][price_data][unit_amount]': (amount * 100).toInt().toString(),
      'line_items[0][quantity]': '1',
      'mode': 'payment',
      'success_url':
          'intent://payment-success?session_id={CHECKOUT_SESSION_ID}&reservation_id=$reservationId#Intent;scheme=my-mobility-services;package=com.example.my_mobility_services;end',
      'cancel_url':
          'intent://payment-cancel#Intent;scheme=my-mobility-services;package=com.example.my_mobility_services;end',
      'metadata[reservation_id]': reservationId,
      'payment_method_options[card][request_three_d_secure]': 'automatic',
      'automatic_tax[enabled]': 'false',
      'custom_text[submit][message]':
          'Merci de votre confiance ! Votre réservation sera confirmée immédiatement.',
      'consent_collection[terms_of_service]': 'required',
      'custom_text[terms_of_service_acceptance][message]':
          'En effectuant ce paiement, vous acceptez nos conditions d\'utilisation.',
      'customer_creation': 'always',
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${await _stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur Stripe: ${response.statusCode} - ${response.body}');
    }
  }

  // ✅ Mettre à jour la réservation dans Firestore après paiement réussi (méthode statique)
  static Future<String?> _handleSuccessfulPayment({
    required String reservationId,
    required String paymentIntentId,
    required double amount,
    required String currency,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final reservationRef = firestore.collection('reservations').doc(reservationId);
      final reservationSnapshot = await reservationRef.get();
      if (!reservationSnapshot.exists) {
        return null;
      }

      final data = reservationSnapshot.data()!;
      final currentStatus = data['status'] as String? ?? ReservationStatus.pending.name;

      if (currentStatus == ReservationStatus.cancelled.name) {
        await _refundPaymentIntent(paymentIntentId);
        await reservationRef.update({
          'paymentStatus': 'refunded',
          'refundProcessedAt': Timestamp.now(),
          'waitingForPayment': false,
          'lastUpdated': Timestamp.now(),
        });
        await _markCustomOfferRefunded(reservationId);
        return ReservationStatus.cancelled.name;
      }

      final updates = <String, dynamic>{
        'paymentStatus': 'paid',
        'paymentIntentId': paymentIntentId,
        'paymentCompletedAt': Timestamp.now(),
        'isPaid': true,
        'waitingForPayment': false,
        'paymentMethod': 'Carte bancaire',
        'lastUpdated': Timestamp.now(),
        'paymentAmount': amount,
        'paymentCurrency': currency,
      };

      var resultingStatus = currentStatus;
      if (currentStatus == ReservationStatus.pending.name ||
          currentStatus == ReservationStatus.confirmed.name) {
        resultingStatus = ReservationStatus.confirmed.name;
        updates['status'] = resultingStatus;
      }

      await reservationRef.update(updates);
      await _markCustomOfferAsPaid(reservationId, promoteToInProgress: false);
      return resultingStatus;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _markCustomOfferAsPaid(String reservationId, {required bool promoteToInProgress}) async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore
        .collection('custom_offers')
        .where('reservationId', isEqualTo: reservationId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return;
    }
    final snapshot = query.docs.first;
    final data = snapshot.data();
    if (data['status'] == ReservationStatus.cancelled.name) {
      return;
    }
    final updates = <String, dynamic>{
      'paymentMethod': 'Carte bancaire',
      'confirmedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
    if (promoteToInProgress && data['status'] == ReservationStatus.confirmed.name) {
      updates['status'] = ReservationStatus.inProgress.name;
    }
    await firestore.collection('custom_offers').doc(snapshot.id).update(updates);
  }

  static Future<void> _markCustomOfferRefunded(String reservationId) async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore
        .collection('custom_offers')
        .where('reservationId', isEqualTo: reservationId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return;
    }
    final snapshot = query.docs.first;
    await firestore.collection('custom_offers').doc(snapshot.id).update({
      'status': ReservationStatus.cancelled.name,
      'refundStatus': 'refunded',
      'refundProcessedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> _refundPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/refunds'),
        headers: {
          'Authorization': 'Bearer ${await _stripeSecretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_intent': paymentIntentId,
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
    } catch (e) {
    }
  }
}
