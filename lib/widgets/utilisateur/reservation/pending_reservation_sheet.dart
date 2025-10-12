import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

/// Widget pour afficher le sheet de réservation en attente de confirmation
class PendingReservationSheet extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onCancel;
  final VoidCallback? onMessage;

  const PendingReservationSheet({
    super.key,
    required this.reservation,
    this.onCancel,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          _buildStatusHeader(context),
          const SizedBox(height: 16),
          
          // Informations de la réservation
          _buildReservationInfo(context),
          const SizedBox(height: 16),
          
          // Message d'information
          _buildInfoMessage(context),
          const SizedBox(height: 20),
          
          // Boutons d'action
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.schedule,
            color: Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.hasCounterOffer 
                    ? 'CONTRE-OFFRE DU CHAUFFEUR !'
                    : 'Réservation en attente',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'En attente de confirmation du chauffeur',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textWeak,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'En attente de confirmation',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationInfo(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reservation.vehicleName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${reservation.departure} → ${reservation.destination}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date et heure avec contre-offre si applicable (comme dans l'ancien code)
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              // Affichage spécial pour les contre-offres
              if (reservation.hasCounterOffer && reservation.driverProposedDate != null && reservation.driverProposedTime != null) ...[
                // Vérifier si la date a changé
                Builder(
                  builder: (context) {
                    // Vérifier si la date a changé (comparer seulement jour/mois/année)
                    final selectedDateOnly = DateTime(
                      reservation.selectedDate.year,
                      reservation.selectedDate.month,
                      reservation.selectedDate.day,
                    );
                    final proposedDateOnly = DateTime(
                      reservation.driverProposedDate!.year,
                      reservation.driverProposedDate!.month,
                      reservation.driverProposedDate!.day,
                    );
                    final dateChanged = !selectedDateOnly.isAtSameMomentAs(proposedDateOnly);
                    
                    // Vérifier si l'heure a changé
                    final timeChanged = reservation.selectedTime != reservation.driverProposedTime;
                    
                    if (dateChanged || timeChanged) {
                      return Row(
                        children: [
                          // Ancienne heure barrée
                          Text(
                            '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Flèche
                          const Icon(Icons.arrow_forward, color: AppColors.accent, size: 16),
                          const SizedBox(width: 8),
                          // Nouvelle heure en gras
                          Text(
                            '${reservation.driverProposedDate!.day}/${reservation.driverProposedDate!.month} à ${reservation.driverProposedTime}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Aucun changement, affichage normal
                      return Text(
                        '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      );
                    }
                  },
                ),
              ] else ...[
                // Réservation normale : afficher la date/heure du client
                Text(
                  '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reservation.hasCounterOffer 
            ? AppColors.accent.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: reservation.hasCounterOffer 
              ? AppColors.accent.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            reservation.hasCounterOffer ? Icons.local_offer : Icons.info_outline,
            color: reservation.hasCounterOffer ? AppColors.accent : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reservation.hasCounterOffer 
                  ? 'Le chauffeur a proposé une contre-offre ! Validez et payez pour confirmer.'
                  : 'Votre réservation est en cours de traitement. Vous ne pouvez pas faire une nouvelle réservation tant qu\'elle n\'est pas confirmée.',
              style: TextStyle(
                fontSize: 14,
                color: reservation.hasCounterOffer ? AppColors.accent : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton Annuler
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close, size: 20),
                const SizedBox(width: 8),
                Text('Annuler la réservation'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Bulle message vers le chat de la course
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble, size: 18),
            label: Text(AppLocalizations.of(context).chat),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
          ),
        ),
      ],
    );
  }
}
