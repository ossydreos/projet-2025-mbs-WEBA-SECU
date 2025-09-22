import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeCheckoutService {
  static const String _stripePublishableKey = 'pk_test_51SA4Pk0xP2bV4rW1o0e3BSzzRNOICsoXLfA2hexPWAaRvNYxYGpM9EXZeOibyR0NMhAeMJoDR9XsM8NVBCbqWxpt00Vr2CovbL';
  static const String _stripeSecretKey = 'sk_test_51SA4Pk0xP2bV4rW12MnpPYIjYeNTOJCYIES1TramydQGjEtqw0uUnYYJBwWjAIyVAOjK2VKsLEzva0kTIWIg9svj00j2ERKneZ';

  // ✅ NOUVELLE MÉTHODE : Stripe Elements avec Twint forcé
  static Future<void> createPaymentIntent({
    required double amount,
    required String currency,
    required String reservationId,
    required String vehicleName,
    required String departure,
    required String destination,
  }) async {
    try {
      // 1. Créer un PaymentIntent avec Twint
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        reservationId: reservationId,
        vehicleName: vehicleName,
        departure: departure,
        destination: destination,
      );

      // 2. Confirmer le paiement avec Stripe Elements
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: null, // Pas de données spécifiques pour l'instant
      );

    } catch (e) {
      throw Exception('Erreur lors du paiement: $e');
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
      'payment_method_types[0]': 'card',
      'payment_method_types[1]': 'twint', // Twint forcé
      'metadata[reservation_id]': reservationId,
      'metadata[vehicle_name]': vehicleName,
      'metadata[departure]': departure,
      'metadata[destination]': destination,
      'automatic_payment_methods[enabled]': 'true',
      'automatic_payment_methods[allow_redirects]': 'never',
      // ✅ Forcer Google Pay et Apple Pay
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

  // Créer un lien de paiement Stripe Checkout
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

  // ✅ Créer une session Stripe via l'API
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
      'success_url': 'https://your-app.com/success?session_id={CHECKOUT_SESSION_ID}',
      'cancel_url': 'https://your-app.com/cancel',
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

  // Afficher un dialog de paiement
  static void showPaymentDialog({
    required BuildContext context,
    required double amount,
    required String currency,
    required String reservationId,
    required String vehicleName,
    required String departure,
    required String destination,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  AppLocalizations.of(context).securePayment,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context).vehicle}: $vehicleName',
                  style: TextStyle(color: AppColors.textWeak),
                ),
                Text(
                  '$departure → $destination',
                  style: TextStyle(color: AppColors.textWeak),
                ),
                const SizedBox(height: 16),
                Text(
                  '${AppLocalizations.of(context).total}: ${amount.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Vous allez être redirigé vers Stripe pour effectuer le paiement sécurisé.',
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
                        onPressed: () => Navigator.pop(context),
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassButton(
                        label: 'Payer maintenant',
                        onPressed: () async {
                          Navigator.pop(context);
                          await createCheckoutSession(
                            amount: amount,
                            currency: currency,
                            reservationId: reservationId,
                            vehicleName: vehicleName,
                            departure: departure,
                            destination: destination,
                          );
                        },
                        primary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
