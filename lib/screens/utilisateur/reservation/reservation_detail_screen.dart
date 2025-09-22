import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/notification_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final NotificationService _notificationService = NotificationService();

  Future<void> _confirmPayment() async {
    try {
      await _notificationService.confirmPayment(widget.reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).paymentConfirmed),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).errorUnknownError}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).reservationDetails,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de base de la réservation
              _buildReservationInfo(),

              const SizedBox(height: 20),

              // Message du chauffeur si contre-offre
              if (widget.reservation.hasCounterOffer &&
                  widget.reservation.adminMessage != null &&
                  widget.reservation.adminMessage!.isNotEmpty) ...[
                _buildDriverMessageSection(),
                const SizedBox(height: 20),
              ],

              // Bouton de paiement si en attente
              if (widget.reservation.status == ReservationStatus.confirmed) ...[
                _buildPaymentSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            ).reservationNumber(widget.reservation.id.substring(0, 8)),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoRow(
            AppLocalizations.of(context).vehicle,
            widget.reservation.vehicleName,
          ),
          _buildInfoRow(
            AppLocalizations.of(context).departure,
            widget.reservation.departure,
          ),
          _buildInfoRow(
            AppLocalizations.of(context).destination,
            widget.reservation.destination,
          ),
          // Afficher la date et heure selon qu'il s'agit d'une contre-offre ou non
          if (widget.reservation.hasCounterOffer &&
              widget.reservation.driverProposedDate != null &&
              widget.reservation.driverProposedTime != null) ...[
            Builder(
              builder: (context) {
                // Vérifier si la date a changé (comparer seulement jour/mois/année)
                final selectedDateOnly = DateTime(
                  widget.reservation.selectedDate.year,
                  widget.reservation.selectedDate.month,
                  widget.reservation.selectedDate.day,
                );
                final proposedDateOnly = DateTime(
                  widget.reservation.driverProposedDate!.year,
                  widget.reservation.driverProposedDate!.month,
                  widget.reservation.driverProposedDate!.day,
                );
                final dateChanged = !selectedDateOnly.isAtSameMomentAs(
                  proposedDateOnly,
                );

                // Vérifier si l'heure a changé
                final timeChanged =
                    widget.reservation.selectedTime !=
                    widget.reservation.driverProposedTime;

                return Column(
                  children: [
                    // Afficher la date (barrée seulement si elle a changé)
                    if (dateChanged)
                      _buildCounterOfferInfoRow(
                        AppLocalizations.of(context).date,
                        '${widget.reservation.selectedDate.day}/${widget.reservation.selectedDate.month}/${widget.reservation.selectedDate.year}',
                        '${widget.reservation.driverProposedDate!.day}/${widget.reservation.driverProposedDate!.month}/${widget.reservation.driverProposedDate!.year}',
                      )
                    else
                      _buildInfoRow(
                        AppLocalizations.of(context).date,
                        '${widget.reservation.selectedDate.day}/${widget.reservation.selectedDate.month}/${widget.reservation.selectedDate.year}',
                      ),

                    // Afficher l'heure (barrée seulement si elle a changé)
                    if (timeChanged)
                      _buildCounterOfferInfoRow(
                        AppLocalizations.of(context).time,
                        widget.reservation.selectedTime,
                        widget.reservation.driverProposedTime!,
                      )
                    else
                      _buildInfoRow(
                        AppLocalizations.of(context).time,
                        widget.reservation.selectedTime,
                      ),
                  ],
                );
              },
            ),
          ] else ...[
            // Réservation normale : afficher la date/heure du client
            _buildInfoRow(
              AppLocalizations.of(context).date,
              '${widget.reservation.selectedDate.day}/${widget.reservation.selectedDate.month}/${widget.reservation.selectedDate.year}',
            ),
            _buildInfoRow(
              AppLocalizations.of(context).time,
              widget.reservation.selectedTime,
            ),
          ],
          _buildInfoRow(
            AppLocalizations.of(context).price,
            '${widget.reservation.totalPrice.toStringAsFixed(2)} €',
          ),
          if (widget.reservation.discountAmount != null)
            _buildInfoRow(
              'Remise',
              '- ${widget.reservation.discountAmount!.toStringAsFixed(2)} €',
            ),
          if (widget.reservation.promoCode != null)
            _buildInfoRow('Code promo', widget.reservation.promoCode!),
          _buildInfoRow(
            AppLocalizations.of(context).status,
            widget.reservation.status.getLocalizedStatus(context),
          ),

          if (widget.reservation.clientNote != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              AppLocalizations.of(context).note,
              widget.reservation.clientNote!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.textWeak, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterOfferInfoRow(
    String label,
    String oldValue,
    String newValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.textWeak, fontSize: 14),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  oldValue,
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.accent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newValue,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverMessageSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).driverMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Text(
              widget.reservation.adminMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).payment,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            AppLocalizations.of(context).paymentDescription,
            style: TextStyle(color: AppColors.textWeak, fontSize: 14),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).cashPayment,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmPayment,
              icon: const Icon(Icons.check_circle, size: 20),
              label: Text(AppLocalizations.of(context).confirmPayment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
