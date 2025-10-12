import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
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
    } catch (e) {
      throw Exception('Erreur lors de la création de la session de paiement: $e');
    }
  }

  // ✅ Vérifier le statut du paiement en arrière-plan
  static void _startPaymentVerification(String reservationId, String sessionId) {
    // Vérifier plus fréquemment pour une mise à jour plus rapide
    Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        final session = await _getStripeSession(sessionId);
        final paymentStatus = session['payment_status'];
        final sessionStatus = session['status'];
        if (paymentStatus == 'paid' || sessionStatus == 'complete') {
          // ✅ Paiement confirmé, mettre à jour la base de données
          await _updateReservationAfterPaymentStatic(
            reservationId: reservationId,
            paymentIntentId: session['payment_intent'],
            amount: (session['amount_total'] / 100).toDouble(),
            currency: session['currency'],
          );
          // Passer en inProgress
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('reservations').doc(reservationId).update({
            'status': ReservationStatus.inProgress.name,
            'lastUpdated': Timestamp.now(),
          });
          timer.cancel(); // Arrêter la vérification
        } else if (session['payment_status'] == 'unpaid' && 
                   DateTime.now().millisecondsSinceEpoch - session['created'] * 1000 > 300000) {
          // Timeout après 5 minutes
          timer.cancel();
        }
      } catch (e) {
        print('Erreur vérification paiement: $e');
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
  static Future<void> finalizePaymentFromDeepLink({
    required String sessionId,
    required String reservationId,
  }) async {
    try {
      final session = await _getStripeSession(sessionId);
      final paymentStatus = session['payment_status'];
      final sessionStatus = session['status'];
      if (paymentStatus == 'paid' || sessionStatus == 'complete') {
        await _updateReservationAfterPaymentStatic(
          reservationId: reservationId,
          paymentIntentId: session['payment_intent'],
          amount: (session['amount_total'] / 100).toDouble(),
          currency: session['currency'],
        );
        // Passer en inProgress immédiatement après confirmation
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('reservations').doc(reservationId).update({
          'status': ReservationStatus.inProgress.name,
          'lastUpdated': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Erreur finalisation deep link: $e');
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
        'payment_method_types[0]': 'card',    // Carte bancaire
        'payment_method_types[1]': 'twint',  // Twint
        'line_items[0][price_data][currency]': currency.toLowerCase(),
      'line_items[0][price_data][product_data][name]': 'Réservation $vehicleName',
      'line_items[0][price_data][product_data][description]': 'De $departure vers $destination',
      'line_items[0][price_data][unit_amount]': (amount * 100).toInt().toString(),
      'line_items[0][quantity]': '1',
      'mode': 'payment',
      // Redirection directe vers l'app via scheme (schéma plus standard)
      'success_url': 'intent://payment-success?session_id={CHECKOUT_SESSION_ID}&reservation_id=' + reservationId + '#Intent;scheme=my-mobility-services;package=com.example.my_mobility_services;end',
      'cancel_url': 'intent://payment-cancel#Intent;scheme=my-mobility-services;package=com.example.my_mobility_services;end',
      'metadata[reservation_id]': reservationId,
      // ✅ Configuration pour Apple Pay et Google Pay
      'payment_method_options[card][request_three_d_secure]': 'automatic',
      'automatic_tax[enabled]': 'false',
      
      // 🎨 PERSONNALISATION DE LA PAGE STRIPE CHECKOUT
      'custom_text[submit][message]': 'Merci de votre confiance ! Votre réservation sera confirmée immédiatement.',
      'consent_collection[terms_of_service]': 'required',
      'custom_text[terms_of_service_acceptance][message]': 'En effectuant ce paiement, vous acceptez nos conditions d\'utilisation.',
      
      // 🎨 COULEURS ET BRANDING (si configuré dans le dashboard Stripe)
      // Pas de collecte d'adresse pour Twint
      
      // 📱 Configuration mobile optimisée
      // Pas de collecte de téléphone
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
        'paymentMethod': 'Carte bancaire',
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
        'paymentMethod': 'Carte bancaire',
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
