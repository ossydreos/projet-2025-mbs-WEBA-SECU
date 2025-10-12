import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

enum RefusalAction { refuse, counterOffer }

class PendingReservationsWidget extends StatefulWidget {
  const PendingReservationsWidget({super.key});

  @override
  State<PendingReservationsWidget> createState() =>
      _PendingReservationsWidgetState();
}

class _PendingReservationsWidgetState extends State<PendingReservationsWidget> {
  final ReservationService _reservationService = ReservationService();

  Future<void> _confirmReservation(Reservation reservation) async {
    try {
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.confirmed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation confirmée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final action = await _showRefusalDialog();

    switch (action) {
      case RefusalAction.refuse:
        try {
          await _reservationService.updateReservationStatus(
            reservation.id,
            ReservationStatus.cancelled,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Réservation refusée'),
                backgroundColor: Colors.orange,
              ),
            );
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
        break;
      case RefusalAction.counterOffer:
        await _showCounterOfferDialog(reservation);
        break;
      case null:
        // Annulé
        break;
    }
  }

  Future<RefusalAction?> _showRefusalDialog() async {
    return showDialog<RefusalAction>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Action sur la réservation',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Que souhaitez-vous faire avec cette réservation ?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(RefusalAction.refuse),
              child: Text(AppLocalizations.of(context).refuse, style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(RefusalAction.counterOffer),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(AppLocalizations.of(context).counterOffer),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCounterOfferDialog(Reservation reservation) async {
    DateTime selectedDate = reservation.selectedDate;
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(reservation.selectedTime.split(':')[0]),
      minute: int.parse(reservation.selectedTime.split(':')[1]),
    );
    final TextEditingController messageController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Proposer une nouvelle date/heure',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date/heure actuelle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date/heure actuelle:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} à ${selectedTime.format(context)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nouvelle date
                const Text(
                  'Nouvelle date:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nouvelle heure
                const Text(
                  'Nouvelle heure:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                const Text(
                  'Message (optionnel):',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).explainChange,
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTime =
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                Navigator.of(context).pop({
                  'newDate': selectedDate,
                  'newTime': newTime,
                  'message': messageController.text,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(AppLocalizations.of(context).propose),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _sendCounterOffer(
        reservation,
        result['newDate'],
        result['newTime'],
        result['message'] ?? '',
      );
    }
  }

  Future<void> _sendCounterOffer(
    Reservation reservation,
    DateTime newDate,
    String newTime,
    String message,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservation.id)
          .update({
            'hasCounterOffer': true,
            'driverProposedDate': Timestamp.fromDate(
              DateTime.utc(newDate.year, newDate.month, newDate.day),
            ),
            'driverProposedTime': newTime,
            'adminMessage': message,
            'status': ReservationStatus.confirmed.name,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contre-offre envoyée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reservationService.getReservationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reservations = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Reservation.fromMap({...data, 'id': doc.id});
        }).toList();

        // Filtrer les réservations en attente d'action admin
        // Prendre toutes les réservations en attente ET toutes les confirmations (normales + contre-offres)
        // Exclure les réservations inProgress (déjà payées)
        final pendingReservations = reservations.where((reservation) {
          return reservation.status == ReservationStatus.pending ||
              reservation.status == ReservationStatus.confirmed;
        }).toList();

        if (pendingReservations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: pendingReservations
              .map((reservation) => _buildPendingReservationCard(reservation))
              .toList(),
        );
      },
    );
  }

  Widget _buildPendingReservationCard(Reservation reservation) {
    final hasCounterOffer = reservation.hasCounterOffer;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône véhicule, nom client et prix
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reservation.userName != null)
                      Text(
                        reservation.userName!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      reservation.vehicleName,
                      style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                    ),
                  ],
                ),
              ),
              // Prix
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasCounterOffer ? 'Prix original' : 'Prix total',
                    style: TextStyle(fontSize: 12, color: AppColors.textWeak),
                  ),
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasCounterOffer
                          ? AppColors.textWeak
                          : AppColors.accent,
                      decoration: hasCounterOffer
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informations de trajet
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Point de départ
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reservation.departure,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Ligne de connexion
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 1,
                        height: 20,
                        color: AppColors.textWeak.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Point d'arrivée
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.hot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reservation.destination,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Informations temporelles
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Départ',
                    style: TextStyle(fontSize: 12, color: AppColors.textWeak),
                  ),
                  Text(
                    reservation.selectedTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date et mode de paiement
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.textWeak, size: 16),
              const SizedBox(width: 8),
              // Afficher la date avec contre-offre si applicable
              if (reservation.hasCounterOffer &&
                  reservation.driverProposedDate != null) ...[
                // Vérifier si la date a changé
                Builder(
                  builder: (context) {
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

                    if (selectedDateOnly != proposedDateOnly) {
                      return Row(
                        children: [
                          Text(
                            '${reservation.selectedDate.day}/${reservation.selectedDate.month}/${reservation.selectedDate.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textWeak,
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
                          Text(
                            '${reservation.driverProposedDate!.day}/${reservation.driverProposedDate!.month}/${reservation.driverProposedDate!.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Text(
                        '${reservation.selectedDate.day}/${reservation.selectedDate.month}/${reservation.selectedDate.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textWeak,
                        ),
                      );
                    }
                  },
                ),
              ] else ...[
                Text(
                  '${reservation.selectedDate.day}/${reservation.selectedDate.month}/${reservation.selectedDate.year}',
                  style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                ),
              ],
              const Spacer(),
              Icon(Icons.payment, color: AppColors.textWeak, size: 16),
              const SizedBox(width: 8),
              Text(
                reservation.paymentMethod,
                style: TextStyle(fontSize: 14, color: AppColors.textWeak),
              ),
            ],
          ),

          // Affichage du code promo utilisé si applicable
          if (reservation.promoCode != null &&
              reservation.promoCode!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_offer, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code promo utilisé:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              reservation.promoCode!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (reservation.discountAmount != null &&
                                reservation.discountAmount! > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(-${reservation.discountAmount!.toStringAsFixed(2)} CHF)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Note du client (si présente)
          if (reservation.clientNote != null &&
              reservation.clientNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.clientNote!,
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Boutons d'action ou barre d'attente
          if (reservation.waitingForPayment == true) ...[
            // Barre d'attente de paiement
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.8),
                    AppColors.accent.withOpacity(0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'En attente du paiement du client',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Le client doit valider et payer sa réservation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.payment, color: Colors.white, size: 24),
                ],
              ),
            ),
          ] else ...[
            // Boutons d'action normaux
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmReservation(reservation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      hasCounterOffer ? 'Confirmer contre-offre' : 'Confirmer',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelReservation(reservation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(hasCounterOffer ? 'Nouvelle offre' : 'Refuser'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
