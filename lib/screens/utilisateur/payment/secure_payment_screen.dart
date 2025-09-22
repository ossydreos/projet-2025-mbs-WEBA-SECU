import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/services/payment_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

class SecurePaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String reservationId;
  final String vehicleName;
  final String departure;
  final String destination;

  const SecurePaymentScreen({
    super.key,
    required this.amount,
    required this.currency,
    required this.reservationId,
    required this.vehicleName,
    required this.departure,
    required this.destination,
  });

  @override
  State<SecurePaymentScreen> createState() => _SecurePaymentScreenState();
}

class _SecurePaymentScreenState extends State<SecurePaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final _cardController = CardFormEditController();
  
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'card';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cardController.addListener(_onCardChanged);
  }

  @override
  void dispose() {
    _cardController.removeListener(_onCardChanged);
    _cardController.dispose();
    super.dispose();
  }

  void _onCardChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      PaymentResult result;

      switch (_selectedPaymentMethod) {
        case 'card':
          if (!_cardController.details.complete) {
            throw Exception('Veuillez remplir tous les champs de la carte');
          }
          result = await _paymentService.processPayment(
            amount: widget.amount,
            currency: widget.currency,
            reservationId: widget.reservationId,
            paymentMethodId: 'card',
          );
          break;
        case 'apple_pay':
          result = await _paymentService.processApplePayPayment(
            amount: widget.amount,
            currency: widget.currency,
            reservationId: widget.reservationId,
          );
          break;
        case 'google_pay':
          result = await _paymentService.processGooglePayPayment(
            amount: widget.amount,
            currency: widget.currency,
            reservationId: widget.reservationId,
          );
          break;
        default:
          throw Exception('Méthode de paiement non supportée');
      }

      if (result.isSuccess) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = result.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Icons.check_circle,
                  color: AppColors.accent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).paymentSuccess,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).paymentSuccessMessage,
                  style: TextStyle(
                    color: AppColors.textWeak,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GlassButton(
                  label: AppLocalizations.of(context).continueText,
                  onPressed: () {
                    Navigator.of(context).pop(); // Fermer le dialog
                    Navigator.of(context).pop(); // Retourner à l'écran précédent
                  },
                  primary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).securePayment,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé de la commande
              _buildOrderSummary(),
              const SizedBox(height: 24),
              
              // Méthodes de paiement
              _buildPaymentMethods(),
              const SizedBox(height: 24),
              
              // Formulaire de carte
              if (_selectedPaymentMethod == 'card') _buildCardForm(),
              
              // Message d'erreur
              if (_errorMessage != null) _buildErrorMessage(),
              
              const SizedBox(height: 24),
              
              // Bouton de paiement
              _buildPaymentButton(),
              
              const SizedBox(height: 16),
              
              // Informations de sécurité
              _buildSecurityInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).orderSummary,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(AppLocalizations.of(context).vehicle, widget.vehicleName),
          _buildSummaryRow(AppLocalizations.of(context).departure, widget.departure),
          _buildSummaryRow(AppLocalizations.of(context).destination, widget.destination),
          const Divider(color: AppColors.textWeak),
          _buildSummaryRow(
            'Total',
            '${widget.amount.toStringAsFixed(2)} ${widget.currency}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.accent : AppColors.textWeak,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppColors.accent : AppColors.textStrong,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).paymentMethod,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildPaymentMethodTile(
                'card',
                Icons.credit_card,
                AppLocalizations.of(context).bankCard,
                AppLocalizations.of(context).bankCardSubtitle,
              ),
              const Divider(color: AppColors.textWeak),
              _buildPaymentMethodTile(
                'apple_pay',
                Icons.apple,
                AppLocalizations.of(context).applePay,
                AppLocalizations.of(context).applePaySubtitle,
              ),
              const Divider(color: AppColors.textWeak),
              _buildPaymentMethodTile(
                'google_pay',
                Icons.g_mobiledata,
                AppLocalizations.of(context).googlePay,
                AppLocalizations.of(context).googlePaySubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String method, IconData icon, String title, String subtitle) {
    final isSelected = _selectedPaymentMethod == method;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accent : AppColors.textWeak,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.accent : AppColors.textStrong,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textWeak,
          fontSize: 12,
        ),
      ),
      trailing: Radio<String>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
            _errorMessage = null;
          });
        },
        activeColor: AppColors.accent,
      ),
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
          _errorMessage = null;
        });
      },
    );
  }

  Widget _buildCardForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).cardDetails,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 16),
          CardFormField(
            controller: _cardController,
            style: CardFormStyle(
              borderColor: AppColors.textWeak,
              borderRadius: 12,
              textColor: AppColors.textStrong,
              backgroundColor: Colors.transparent,
              placeholderColor: AppColors.textWeak,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        label: _isProcessing 
          ? AppLocalizations.of(context).processingPayment
          : '${AppLocalizations.of(context).payNow} ${widget.amount.toStringAsFixed(2)} ${widget.currency}',
        onPressed: _isProcessing ? null : _processPayment,
        primary: true,
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).securePaymentInfo,
              style: TextStyle(
                color: AppColors.textWeak,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
