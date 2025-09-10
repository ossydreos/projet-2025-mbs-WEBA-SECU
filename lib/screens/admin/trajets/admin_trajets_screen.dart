import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';

class AdminTrajetsScreen extends StatefulWidget {
  const AdminTrajetsScreen({super.key});

  @override
  State<AdminTrajetsScreen> createState() => _AdminTrajetsScreenState();
}

class _AdminTrajetsScreenState extends State<AdminTrajetsScreen>
    with TickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 1;
  late TabController _tabController;

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
            title: 'Courses',
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(12),
                  showBorder: true,
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.textStrong,
                    unselectedLabelColor: AppColors.textWeak,
                    dividerColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                    tabs: const [
                      Tab(text: 'À venir'),
                      Tab(text: 'Terminés'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
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
      stream: _reservationService.getConfirmedReservationsStream(),
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
                    'Erreur de chargement',
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
                    'Aucune course à venir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les courses confirmées apparaîtront ici',
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
                    'Erreur de chargement',
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
                    Icons.history,
                    size: 64,
                    color: AppColors.accent.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune course terminée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'L\'historique des courses apparaîtra ici',
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
            );
          },
        );
      },
    );
  }

  Widget _buildReservationCard(
    Reservation reservation, {
    required bool isUpcoming,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.userName ?? 'Utilisateur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reservation.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(reservation.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(reservation.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(reservation.status),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informations du trajet avec composant stylisé
            _buildLocationRow(
              icon: Icons.location_on,
              iconColor: Colors.green,
              label: 'Départ',
              // CORRECTION: Utilisez les bonnes propriétés
              address: reservation.departure,
            ),
            const SizedBox(height: 8),
            _buildLocationRow(
              icon: Icons.flag,
              iconColor: AppColors.hot,
              label: 'Destination',
              // CORRECTION: Utilisez les bonnes propriétés
              address: reservation.destination,
            ),
            const SizedBox(height: 8),
            _buildLocationRow(
              icon: Icons.schedule,
              iconColor: AppColors.accent,
              label: 'Horaire',
              address:
                  '${reservation.selectedDate} à ${reservation.selectedTime}',
            ),

            // Note du client si elle existe
            if (reservation.clientNote != null &&
                reservation.clientNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_alt, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note du client:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reservation.clientNote!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Boutons d'action pour les courses à venir avec style glass
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassActionButton(
                      label: 'Terminer',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onPressed: () => _completeReservation(reservation),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassActionButton(
                      label: 'Annuler',
                      icon: Icons.cancel,
                      color: AppColors.hot,
                      onPressed: () => _showCancelDialog(reservation),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: iconColor.withOpacity(0.5)),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
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
              Text(
                address,
                style: TextStyle(fontSize: 14, color: AppColors.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
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
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.completed,
        updatedAt: DateTime.now(),
      );
      await _reservationService.updateReservation(updatedReservation);
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Theme(
          data: AppTheme.glassDark,
          child: AlertDialog(
            backgroundColor: AppColors.glass,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.glassStroke),
            ),
            title: Text(
              'Annuler la course',
              style: TextStyle(
                color: AppColors.textStrong,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Êtes-vous sûr de vouloir annuler cette course ? Cette action ne peut pas être annulée.',
              style: TextStyle(color: AppColors.text),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Non', style: TextStyle(color: AppColors.textWeak)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              _buildGlassActionButton(
                label: 'Oui, annuler',
                icon: Icons.warning,
                color: AppColors.hot,
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelConfirmedReservation(reservation);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelConfirmedReservation(Reservation reservation) async {
    try {
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.cancelled,
        updatedAt: DateTime.now(),
      );
      await _reservationService.updateReservation(updatedReservation);
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
}
