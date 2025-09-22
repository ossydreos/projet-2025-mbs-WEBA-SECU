import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/data/services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).paymentHistory,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _getPaymentHistoryStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.textWeak,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur lors du chargement',
                      style: TextStyle(
                        color: AppColors.textWeak,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final payments = snapshot.data?.docs ?? [];

            if (payments.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                final data = payment.data() as Map<String, dynamic>;
                
                return _buildPaymentCard(data);
              },
            );
          },
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getPaymentHistoryStream() {
    // TODO: Filtrer par utilisateur connecté
    return _firestore
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: AppColors.textWeak,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noPaymentHistory,
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).noPaymentHistoryMessage,
            style: TextStyle(
              color: AppColors.textWeak,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amount = payment['amount'] ?? 0.0;
    final currency = payment['currency'] ?? 'EUR';
    final status = payment['status'] ?? 'unknown';
    final createdAt = payment['createdAt'] as Timestamp?;
    final reservationId = payment['reservationId'] ?? '';
    final paymentIntentId = payment['paymentIntentId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec montant et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${amount.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            
            // Détails de la transaction
            _buildDetailRow(
              AppLocalizations.of(context).transactionId,
              paymentIntentId.isNotEmpty ? paymentIntentId.substring(0, 12) + '...' : 'N/A',
            ),
            _buildDetailRow(
              AppLocalizations.of(context).paymentDate,
              createdAt != null 
                ? _formatDate(createdAt.toDate())
                : 'N/A',
            ),
            if (reservationId.isNotEmpty)
              _buildDetailRow(
                'Réservation',
                reservationId.substring(0, 8) + '...',
              ),
            
            const SizedBox(height: 12),
            
            // Actions
            if (status == 'paid')
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: 'Voir détails',
                      onPressed: () => _showPaymentDetails(payment),
                      primary: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassButton(
                      label: 'Rembourser',
                      onPressed: () => _showRefundDialog(payment),
                      primary: false,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        label = AppLocalizations.of(context).paid;
        break;
      case 'pending':
        color = Colors.orange;
        label = AppLocalizations.of(context).pending;
        break;
      case 'failed':
        color = Colors.red;
        label = AppLocalizations.of(context).failed;
        break;
      case 'refunded':
        color = Colors.blue;
        label = AppLocalizations.of(context).refunded;
        break;
      default:
        color = AppColors.textWeak;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textWeak,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détails du paiement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Montant', '${payment['amount']} ${payment['currency']}'),
                _buildDetailRow('Statut', payment['status']),
                _buildDetailRow('ID Transaction', payment['paymentIntentId']),
                _buildDetailRow('Date', _formatDate((payment['createdAt'] as Timestamp).toDate())),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Fermer',
                  onPressed: () => Navigator.pop(context),
                  primary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRefundDialog(Map<String, dynamic> payment) {
    final TextEditingController reasonController = TextEditingController();
    
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).refundRequest,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).refundReason,
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: TextStyle(color: AppColors.textStrong),
                  decoration: InputDecoration(
                    hintText: 'Expliquez la raison du remboursement...',
                    hintStyle: TextStyle(color: AppColors.textWeak),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.bgElev.withOpacity(0.5),
                  ),
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
                        label: AppLocalizations.of(context).requestRefund,
                        onPressed: () => _processRefund(payment, reasonController.text),
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

  Future<void> _processRefund(Map<String, dynamic> payment, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez indiquer une raison'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await _paymentService.processRefund(
        paymentIntentId: payment['paymentIntentId'],
        amount: payment['amount'],
        reason: reason,
      );

      Navigator.pop(context); // Fermer le dialog

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).refundSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
