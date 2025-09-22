import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';

class PendingReservationsWidget extends StatefulWidget {
  const PendingReservationsWidget({super.key});

  @override
  State<PendingReservationsWidget> createState() =>
      _PendingReservationsWidgetState();
}

class _PendingReservationsWidgetState extends State<PendingReservationsWidget> {
  final ReservationService _reservationService = ReservationService();

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
        final pendingReservations = reservations.where((reservation) {
          return reservation.status == ReservationStatus.pending &&
              (reservation.toMap()['adminPending'] == true);
        }).toList();

        if (pendingReservations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Réservations en attente (${pendingReservations.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...pendingReservations
                  .map(
                    (reservation) => _buildPendingReservationCard(reservation),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingReservationCard(Reservation reservation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.userName ?? 'Client',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reservation.departure} → ${reservation.destination}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'EN ATTENTE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
