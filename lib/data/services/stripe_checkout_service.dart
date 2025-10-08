import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

class StripeCheckoutService {
  static const String _stripePublishableKey = 'pk_test_51SA4Pk0xP2bV4rW1o0e3BSzzRNOICsoXLfA2hexPWAaRvNYxYGpM9EXZeOibyR0NMhAeMJoDR9XsM8NVBCbqWxpt00Vr2CovbL';
  static const String _stripeSecretKey = 'sk_test_51SA4Pk0xP2bV4rW12MnpPYIjYeNTOJCYIES1TramydQGjEtqw0uUnYYJBwWjAIyVAOjK2VKsLEzva0kTIWIg9svj00j2ERKneZ';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Initialiser Stripe
  static Future<void> initializeStripe() async {
    try {
      Stripe.publishableKey = _stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      print('Erreur initialisation Stripe: $e');
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

      // ✅ Mettre à jour la base de données après paiement réussi
      await _updateReservationAfterPaymentStatic(
        reservationId: reservationId,
        paymentIntentId: paymentResult.id,
        amount: amount,
        currency: currency,
      );

      return {
        'success': true,
        'paymentIntentId': paymentResult.id,
        'status': paymentResult.status,
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
        'Authorization': 'Bearer $_stripeSecretKey',
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
      } else {
        throw Exception('Impossible d\'ouvrir le lien de paiement');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de la session de paiement: $e');
    }
  }

  // ✅ Créer une session Stripe via l'API (pour référence, non utilisée)
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
        'payment_method_types[0]': 'card',    // Carte bancaire
        'payment_method_types[1]': 'twint',  // Twint
        'payment_method_types[2]': 'klarna', // Klarna (si vous voulez)
        'line_items[0][price_data][currency]': currency.toLowerCase(),
      'line_items[0][price_data][product_data][name]': 'Réservation $vehicleName',
      'line_items[0][price_data][product_data][description]': 'De $departure vers $destination',
      'line_items[0][price_data][unit_amount]': (amount * 100).toInt().toString(),
      'line_items[0][quantity]': '1',
      'mode': 'payment',
      'success_url': 'https://my-mobility-services.com/success?session_id={CHECKOUT_SESSION_ID}',
      'cancel_url': 'https://my-mobility-services.com/cancel',
      'metadata[reservation_id]': reservationId,
      // ✅ Configuration pour Apple Pay et Google Pay
      'payment_method_options[card][request_three_d_secure]': 'automatic',
      'automatic_tax[enabled]': 'false',
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
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
  static Future<void> _updateReservationAfterPaymentStatic({
    required String reservationId,
    required String paymentIntentId,
    required double amount,
    required String currency,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('reservations').doc(reservationId).update({
        'paymentStatus': 'paid',
        'paymentIntentId': paymentIntentId,
        'paymentCompletedAt': Timestamp.now(),
        'status': ReservationStatus.confirmed.name,
        'isPaid': true,
        'waitingForPayment': false, // Plus en attente de paiement
        'lastUpdated': Timestamp.now(),
        'paymentAmount': amount,
        'paymentCurrency': currency,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la réservation: $e');
      // Ne pas faire échouer le paiement pour une erreur de BDD
    }
  }

  // ✅ Mettre à jour la réservation dans Firestore après paiement réussi (méthode d'instance)
  Future<void> _updateReservationAfterPayment({
    required String reservationId,
    required String paymentIntentId,
    required double amount,
    required String currency,
  }) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'paymentStatus': 'paid',
        'paymentIntentId': paymentIntentId,
        'paymentCompletedAt': Timestamp.now(),
        'status': ReservationStatus.confirmed.name,
        'isPaid': true,
        'waitingForPayment': false, // Plus en attente de paiement
        'lastUpdated': Timestamp.now(),
        'paymentAmount': amount,
        'paymentCurrency': currency,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la réservation: $e');
      // Ne pas faire échouer le paiement pour une erreur de BDD
    }
  }
}

// ✅ Widget de dialog de paiement intégré
class PaymentDialog extends StatefulWidget {
  final double amount;
  final String currency;
  final String reservationId;
  final String vehicleName;
  final String departure;
  final String destination;

  const PaymentDialog({
    Key? key,
    required this.amount,
    required this.currency,
    required this.reservationId,
    required this.vehicleName,
    required this.departure,
    required this.destination,
  }) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payment,
                color: AppColors.accent,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Paiement sécurisé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Véhicule: ${widget.vehicleName}',
                style: TextStyle(color: AppColors.textWeak),
              ),
              Text(
                '${widget.departure} → ${widget.destination}',
                style: TextStyle(color: AppColors.textWeak),
              ),
              const SizedBox(height: 16),
              Text(
                'Total: ${widget.amount.toStringAsFixed(2)} ${widget.currency}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (_isProcessing) ...[
                CircularProgressIndicator(color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'Traitement du paiement...',
                  style: TextStyle(color: AppColors.textWeak),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Text(
                  'Utilisez une carte de test Stripe pour effectuer le paiement.',
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Annuler',
                        onPressed: () => Navigator.pop(context, {'success': false, 'error': 'Paiement annulé'}),
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassButton(
                        label: 'Payer maintenant',
                        onPressed: _processPayment,
                        primary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await StripeCheckoutService.processPayment(
        amount: widget.amount,
        currency: widget.currency,
        reservationId: widget.reservationId,
        vehicleName: widget.vehicleName,
        departure: widget.departure,
        destination: widget.destination,
      );

      if (result['success']) {
        Navigator.pop(context, result);
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Erreur inconnue';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isProcessing = false;
      });
    }
  }
}
