import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/widgets/widget_navTrajets.dart';

class AdminTrajetsScreen extends StatefulWidget {
  const AdminTrajetsScreen({super.key});

  @override
  State<AdminTrajetsScreen> createState() => _AdminTrajetsScreenState();
}

class _AdminTrajetsScreenState extends State<AdminTrajetsScreen>
    with TickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();

  int _selectedIndex = 1;
  late TabController _tabController;

  // Variables pour le tri
  bool _sortAscending =
      true; // true = plus ancienne à plus récente, false = plus récente à plus ancienne

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.glassDark,
      child: GlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GlassAppBar(
            title: AppLocalizations.of(context).courses,
            actions: [
              // Bouton de test pour vérifier le pop-up global
              IconButton(
                icon: Icon(Icons.notifications_active, color: AppColors.accent),
                tooltip: 'Test notification globale',
                onPressed: () async {
                  try {
                    // Créer une réservation de test
                    final now = DateTime.now();
                    final reservationId =
                        'test-trajets-${now.millisecondsSinceEpoch}';

                    final reservationData = {
                      'id': reservationId,
                      'userId':
                          'test-client-trajets-${now.millisecondsSinceEpoch}',
                      'userName':
                          'Test depuis Trajets ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                      'userEmail': 'test@example.com',
                      'userPhone': '+41 79 123 45 67',
                      'departure': 'Test Departure',
                      'destination': 'Test Destination',
                      'selectedDate': Timestamp.fromDate(now),
                      'selectedTime':
                          '${now.hour.toString().padLeft(2, '0')}:${(now.minute + 5).toString().padLeft(2, '0')}',
                      'estimatedArrival':
                          '${now.hour.toString().padLeft(2, '0')}:${(now.minute + 35).toString().padLeft(2, '0')}',
                      'totalPrice': 25.0,
                      'vehicleName': 'Test Vehicle',
                      'paymentMethod': 'Carte',
                      'status': ReservationStatus.pending.name,
                      'createdAt': Timestamp.fromDate(now),
                      'updatedAt': Timestamp.fromDate(now),
                      'notes': 'Test depuis l\'écran Trajets',
                      'promoCode': null,
                      'discountAmount': 0.0,
                    };

                    // Insérer dans Firestore
                    await FirebaseFirestore.instance
                        .collection('reservations')
                        .doc(reservationId)
                        .set(reservationData);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Réservation créée depuis Trajets ! Pop-up en cours...',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
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
                },
              ),
              // Menu de tri et filtrage
              PopupMenuButton<String>(
                icon: Icon(Icons.tune, color: AppColors.accent),
                tooltip: 'Options de tri et filtrage',
                onSelected: (String value) {
                  switch (value) {
                    case 'sort_asc':
                      setState(() {
                        _sortAscending = true;
                      });
                      break;
                    case 'sort_desc':
                      setState(() {
                        _sortAscending = false;
                      });
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'sort_asc',
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          color: _sortAscending
                              ? AppColors.accent
                              : AppColors.textWeak,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Plus ancienne à plus récente',
                          style: TextStyle(
                            color: _sortAscending
                                ? AppColors.accent
                                : AppColors.textStrong,
                            fontWeight: _sortAscending
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'sort_desc',
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          color: !_sortAscending
                              ? AppColors.accent
                              : AppColors.textWeak,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Plus récente à plus ancienne',
                          style: TextStyle(
                            color: !_sortAscending
                                ? AppColors.accent
                                : AppColors.textStrong,
                            fontWeight: !_sortAscending
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Barre de navigation des onglets séparée
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TrajetNav(_tabController),
              ),
              // Contenu des onglets
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildUpcomingTab(), _buildCompletedTab()],
                ),
              ),
              AdminBottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _handleNavigation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getInProgressReservationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.hot),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).loadingError,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final reservations = snapshot.data ?? [];

        if (reservations.isEmpty) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: AppColors.accent.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).noUpcomingRides,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).upcomingRidesWillAppear,
                    style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(reservations[index], isUpcoming: true);
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getCompletedReservationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.hot),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).loadingError,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        List<Reservation> reservations = snapshot.data ?? [];

        // Trier les réservations par date
        reservations.sort((a, b) {
          if (_sortAscending) {
            return a.createdAt.compareTo(b.createdAt);
          } else {
            return b.createdAt.compareTo(a.createdAt);
          }
        });

        if (reservations.isEmpty) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.accent.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).noCompletedRides,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).rideHistoryWillAppear,
                    style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(
              reservations[index],
              isUpcoming: false,
              showDeleteButton: true,
            );
          },
        );
      },
    );
  }

  Widget _buildReservationCard(
    Reservation reservation, {
    required bool isUpcoming,
    bool showDeleteButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête compact avec statut et ID de course
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course #${reservation.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWeak,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reservation.userName ?? 'Client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reservation.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(reservation.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(reservation.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(reservation.status),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informations compactes du trajet
            _buildCompactLocationRow(
              icon: Icons.location_on,
              iconColor: Colors.green,
              address: reservation.departure,
            ),
            const SizedBox(height: 6),
            _buildCompactLocationRow(
              icon: Icons.flag,
              iconColor: AppColors.hot,
              address: reservation.destination,
            ),
            const SizedBox(height: 8),

            // Date et heure compactes
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.textWeak),
                const SizedBox(width: 6),
                Text(
                  _formatCompactDateTime(
                    reservation.selectedDate,
                    reservation.selectedTime,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textWeak,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Boutons d'action
            Row(
              children: [
                // Bouton détails rond
                _buildRoundDetailsButton(reservation),
                const SizedBox(width: 12),
                // Boutons d'action pour les courses à venir
                if (isUpcoming) ...[
                  Expanded(
                    child: _buildActionButton(
                      label: 'Terminer',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onPressed: () => _completeReservation(reservation),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Annuler',
                      icon: Icons.cancel,
                      color: AppColors.hot,
                      onPressed: () => _showCancelDialog(reservation),
                    ),
                  ),
                ],
                // Bouton de suppression pour les courses terminées
                if (showDeleteButton) ...[
                  Expanded(
                    child: _buildActionButton(
                      label: 'Supprimer',
                      icon: Icons.delete_outline,
                      color: AppColors.hot,
                      onPressed: () => _showDeleteConfirmation(reservation),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Ligne de localisation compacte
  Widget _buildCompactLocationRow({
    required IconData icon,
    required Color iconColor,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Bouton détails rond
  Widget _buildRoundDetailsButton(Reservation reservation) {
    return GestureDetector(
      onTap: () => _showDetailsDialog(reservation),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(Icons.info_outline, size: 18, color: AppColors.accent),
      ),
    );
  }

  // Bouton d'action avec label
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formatage compact des dates
  String _formatCompactDateTime(DateTime date, String time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    String dateText;
    if (selectedDay == today) {
      dateText = 'Aujourd\'hui';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      dateText = 'Demain';
    } else {
      dateText =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }

    return '$dateText à $time';
  }

  // Dialog des détails complets
  void _showDetailsDialog(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Détails de la course #${reservation.id.substring(0, 8)}',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informations du client
                _buildCompactDetailSection(
                  'Client',
                  Icons.person,
                  reservation.userName ?? 'Client',
                ),
                const SizedBox(height: 12),

                // Trajet
                _buildCompactDetailSection(
                  'Départ',
                  Icons.location_on,
                  reservation.departure,
                ),
                const SizedBox(height: 8),
                _buildCompactDetailSection(
                  'Destination',
                  Icons.flag,
                  reservation.destination,
                ),
                const SizedBox(height: 12),

                // Date et heure
                _buildCompactDetailSection(
                  'Date et heure',
                  Icons.schedule,
                  _formatDateTimeWithTimezone(
                    reservation.selectedDate,
                    reservation.selectedTime,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCompactDetailSection(
                  'Arrivée estimée',
                  Icons.access_time,
                  reservation.estimatedArrival,
                ),
                const SizedBox(height: 12),

                // Paiement
                _buildCompactPaymentDetails(reservation),

                // Code promo si applicable
                if (reservation.promoCode != null &&
                    reservation.promoCode!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCompactDetailSection(
                    'Code promo',
                    Icons.local_offer,
                    '${reservation.promoCode!} ${reservation.discountAmount != null && reservation.discountAmount! > 0 ? '(-${_formatSwissCurrency(reservation.discountAmount!)})' : ''}',
                  ),
                ],

                // Note du client si elle existe
                if (reservation.clientNote != null &&
                    reservation.clientNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCompactDetailSection(
                    'Note du client',
                    Icons.note_alt,
                    reservation.clientNote!,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Fermer',
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Section de détail compacte dans le dialog
  Widget _buildCompactDetailSection(String label, IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWeak,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Détails de paiement compacts dans le dialog
  Widget _buildCompactPaymentDetails(Reservation reservation) {
    final basePrice =
        reservation.totalPrice + (reservation.discountAmount ?? 0.0);
    final discount = reservation.discountAmount ?? 0.0;
    final total = reservation.totalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre paiement
        Row(
          children: [
            Icon(Icons.payment, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Paiement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Moyen de paiement
        _buildCompactPaymentRow(
          'Moyen de paiement',
          Icons.credit_card,
          reservation.paymentMethod,
        ),
        const SizedBox(height: 6),

        // Sous-total
        _buildCompactPaymentRow(
          'Sous-total',
          Icons.money,
          _formatSwissCurrency(basePrice),
        ),

        // Remise si applicable
        if (discount > 0) ...[
          const SizedBox(height: 6),
          _buildCompactPaymentRow(
            'Remise',
            Icons.discount,
            '-${_formatSwissCurrency(discount)}',
            isDiscount: true,
          ),
        ],

        const SizedBox(height: 8),

        // Séparateur
        Container(height: 1, color: AppColors.textWeak.withOpacity(0.3)),

        const SizedBox(height: 8),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            Text(
              _formatSwissCurrency(total),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Ligne de paiement compacte dans le dialog
  Widget _buildCompactPaymentRow(
    String label,
    IconData icon,
    String value, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isDiscount ? Colors.green : AppColors.textWeak,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textWeak,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: isDiscount ? Colors.green : AppColors.textStrong,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      // Les statuts counterOffered et waitingPayment n'existent plus
      case ReservationStatus.inProgress:
        return AppColors.accent;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return AppColors.hot;
    }
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      // Les statuts counterOffered et waitingPayment n'existent plus
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
    }
  }

  Future<void> _completeReservation(Reservation reservation) async {
    try {
      // Marquer la course comme terminée avec notification
      await _reservationService.completeReservation(reservation.id);
      if (mounted) {
        _showSuccessMessage('Course marquée comme terminée !');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur: $e');
      }
    }
  }

  Future<void> _showCancelDialog(Reservation reservation) async {
    await showGlassConfirmDialog(
      context: context,
      title: AppLocalizations.of(context).cancelRide,
      message: AppLocalizations.of(context).cancelRideConfirmation,
      confirmText: AppLocalizations.of(context).yesCancel,
      cancelText: AppLocalizations.of(context).no,
      icon: Icons.warning,
      iconColor: AppColors.hot,
      onConfirm: () {
        Navigator.of(context).pop();
        _cancelConfirmedReservation(reservation);
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _cancelConfirmedReservation(Reservation reservation) async {
    try {
      // Annuler la course confirmée avec notification
      await _reservationService.cancelConfirmedReservation(
        reservation.id,
        reason: 'Course annulée par l\'administrateur',
      );
      if (mounted) {
        _showSuccessMessage('Course annulée !');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.hot,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Formatage des dates avec fuseau horaire pour l'admin
  String _formatDateTimeWithTimezone(DateTime date, String time) {
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return 'Départ prévu: $formattedDate, $time (CEST)';
  }

  // Formatage des devises suisses
  String _formatSwissCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Ajouter des apostrophes pour les milliers
    String formattedInteger = integerPart;
    if (integerPart.length > 3) {
      final reversed = integerPart.split('').reversed.join('');
      final withApostrophes = reversed.replaceAllMapped(
        RegExp(r'(\d{3})(?=\d)'),
        (match) => '${match.group(1)}\'',
      );
      formattedInteger = withApostrophes.split('').reversed.join('');
    }

    return 'CHF $formattedInteger.$decimalPart';
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/admin/gestion');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/admin/profile');
        break;
    }
  }

  // Méthodes pour la suppression

  void _showDeleteConfirmation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.hot, size: 24),
              const SizedBox(width: 12),
              Text(
                'Supprimer la course',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir supprimer cette course ?',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course #${reservation.id.substring(0, 8)}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.userName} • ${reservation.departure} → ${reservation.destination}',
                      style: TextStyle(
                        color: AppColors.textWeak,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette action est irréversible.',
                style: TextStyle(
                  color: AppColors.hot,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReservation(reservation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hot,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteReservation(Reservation reservation) async {
    try {
      await _reservationService.deleteReservation(reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Course #${reservation.id.substring(0, 8)} supprimée',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
