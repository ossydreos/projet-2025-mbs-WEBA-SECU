import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/notification_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _counterOffers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounterOffers();
  }

  Future<void> _loadCounterOffers() async {
    try {
      final counterOffers = await _notificationService
          .getCounterOffersForReservation(widget.reservation.id);
      setState(() {
        _counterOffers = counterOffers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptCounterOffer(Map<String, dynamic> counterOffer) async {
    try {
      await _notificationService.acceptCounterOffer(
        counterOffer['id'],
        widget.reservation.id,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contre-offre acceptée ! Vous pouvez maintenant payer.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCounterOffer(Map<String, dynamic> counterOffer) async {
    try {
      await _notificationService.rejectCounterOffer(counterOffer['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contre-offre rejetée.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadCounterOffers(); // Recharger la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmPayment() async {
    try {
      await _notificationService.confirmPayment(widget.reservation.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement confirmé ! Votre course est confirmée.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
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
          title: 'Détails de la réservation',
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations de base de la réservation
                    _buildReservationInfo(),
                    
                    const SizedBox(height: 20),
                    
                    // Contre-offres si disponibles
                    if (_counterOffers.isNotEmpty) ...[
                      _buildCounterOffersSection(),
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
            'Réservation #${widget.reservation.id.substring(0, 8)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Véhicule', widget.reservation.vehicleName),
          _buildInfoRow('Départ', widget.reservation.departure),
          _buildInfoRow('Destination', widget.reservation.destination),
          // Afficher la date et heure selon qu'il s'agit d'une contre-offre ou non
          if (widget.reservation.hasCounterOffer && widget.reservation.driverProposedDate != null && widget.reservation.driverProposedTime != null) ...[
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
                final dateChanged = !selectedDateOnly.isAtSameMomentAs(proposedDateOnly);
                
                // Vérifier si l'heure a changé
                final timeChanged = widget.reservation.selectedTime != widget.reservation.driverProposedTime;
                
                return Column(
                  children: [
                    // Afficher la date (barrée seulement si elle a changé)
                    if (dateChanged) 
                      _buildCounterOfferInfoRow('Date', 
                        '${widget.reservation.selectedDate.day}/${widget.reservation.selectedDate.month}/${widget.reservation.selectedDate.year}',
                        '${widget.reservation.driverProposedDate!.day}/${widget.reservation.driverProposedDate!.month}/${widget.reservation.driverProposedDate!.year}'
                      )
                    else 
                      _buildInfoRow('Date', '${widget.reservation.selectedDate.day}/${widget.reservation.selectedDate.month}/${widget.reservation.selectedDate.year}'),
                    
                    // Afficher l'heure (barrée seulement si elle a changé)
                    if (timeChanged) 
                      _buildCounterOfferInfoRow('Heure', 
                        widget.reservation.selectedTime,
                        widget.reservation.driverProposedTime!
                      )
                    else 
                      _buildInfoRow('Heure', widget.reservation.selectedTime),
                  ],
                );
              },
            ),
          ] else ...[
            // Réservation normale : afficher la date/heure du client
            _buildInfoRow('Date', '${widget.reservation.selectedDate.day}/${widget.reservation.selectedDate.month}/${widget.reservation.selectedDate.year}'),
            _buildInfoRow('Heure', widget.reservation.selectedTime),
          ],
          _buildInfoRow('Prix', '${widget.reservation.totalPrice.toStringAsFixed(2)} €'),
          _buildInfoRow('Statut', widget.reservation.status.statusInFrench),
          
          if (widget.reservation.clientNote != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Note', widget.reservation.clientNote!),
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
              style: const TextStyle(
                color: AppColors.textWeak,
                fontSize: 14,
              ),
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

  Widget _buildCounterOfferInfoRow(String label, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textWeak,
                fontSize: 14,
              ),
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
                const Icon(Icons.arrow_forward, color: AppColors.accent, size: 16),
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

  Widget _buildCounterOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contre-offres reçues',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        
        ..._counterOffers.map((counterOffer) => _buildCounterOfferCard(counterOffer)),
      ],
    );
  }

  Widget _buildCounterOfferCard(Map<String, dynamic> counterOffer) {
    final proposedDate = (counterOffer['proposedDate'] as Timestamp).toDate();
    final proposedTime = counterOffer['proposedTime'] as String;
    final message = counterOffer['adminMessage'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nouvelle proposition',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Nouvelle date', '${proposedDate.day}/${proposedDate.month}/${proposedDate.year}'),
          _buildInfoRow('Nouvelle heure', proposedTime),
          
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Message', message),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptCounterOffer(counterOffer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Accepter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectCounterOffer(counterOffer),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Rejeter'),
                ),
              ),
            ],
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
              const Text(
                'Paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text(
            'Votre réservation a été confirmée par le chauffeur. Vous pouvez maintenant procéder au paiement.',
            style: TextStyle(
              color: AppColors.textWeak,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Paiement en espèces à la fin du trajet',
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
              label: const Text('Confirmer le paiement'),
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
