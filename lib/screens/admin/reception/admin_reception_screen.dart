import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart'; // Import du nouveau thème
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';

class AdminReceptionScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const AdminReceptionScreen({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<AdminReceptionScreen> createState() => _AdminReceptionScreenState();
}

class _AdminReceptionScreenState extends State<AdminReceptionScreen> {
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      // Nouveau fond glassmorphism
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Transparent pour laisser apparaître le fond
        appBar: GlassAppBar(
          // Nouvelle AppBar glassmorphism
          title: 'Boîte de réception',
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ),
        body: Column(
          children: [
            // Contenu principal
            Expanded(child: _buildContent()),
            // Barre de navigation en bas
            if (widget.showBottomBar)
              AdminBottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _handleNavigation,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildPendingReservations(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getPendingReservationsStream(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.length ?? 0;

        return StreamBuilder<List<Reservation>>(
          stream: _reservationService.getConfirmedReservationsStream(),
          builder: (context, confirmedSnapshot) {
            final confirmedCount = confirmedSnapshot.data?.length ?? 0;

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'En attente',
                    count: pendingCount,
                    color: Colors.blue,
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Confirmées',
                    count: confirmedCount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return GlassContainer(
      // Remplacement par GlassContainer
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors
                  .textStrong, // Utilisation des couleurs du nouveau thème
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textWeak, // Couleur texte secondaire
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReservations() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getPendingReservationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.accent, // Couleur d'accent du nouveau thème
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.hot, // Couleur pour les erreurs
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: TextStyle(color: AppColors.hot),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GlassButton(
                  // Nouveau bouton glassmorphism
                  label: 'Réessayer',
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        }

        final reservations = snapshot.data ?? [];

        if (reservations.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Réservations en attente (${reservations.length})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong, // Couleur principale du texte
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return _buildReservationCard(reservation);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      // Remplacement par GlassContainer
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 64, color: AppColors.textWeak),
          const SizedBox(height: 16),
          Text(
            'Aucune réservation en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouvelles réservations apparaîtront ici',
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GlassButton(
            // Nouveau bouton glassmorphism
            label: 'Créer une réservation de test',
            onPressed: _createTestReservation,
            primary: true,
          ),
        ],
      ),
    );
  }

  void _createTestReservation() async {
    try {
      final now = TimeOfDay.now();
      final testReservation = Reservation(
        id: '',
        userId: 'test_user_123',
        userName: 'Marie Martin',
        vehicleName: 'Berline Économique',
        departure: 'Place de la République, Paris',
        destination: 'Gare du Nord, Paris',
        selectedDate: DateTime.now().add(Duration(days: 1)),
        selectedTime:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        estimatedArrival:
            '${now.hour.toString().padLeft(2, '0')}:${(now.minute + 13).toString().padLeft(2, '0')}',
        paymentMethod: 'Espèces',
        totalPrice: 6.0, // Prix calculé pour ~5km avec véhicule économique (1.20€/km)
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
      );

      await _reservationService.createReservation(testReservation);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation de test créée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.hot),
      );
    }
  }

  void _confirmReservation(Reservation reservation) async {
    try {
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.confirmed,
        updatedAt: DateTime.now(),
      );

      await _reservationService.updateReservation(updatedReservation);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation confirmée !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la confirmation: $e'),
          backgroundColor: AppColors.hot,
        ),
      );
    }
  }

  void _cancelReservation(Reservation reservation) async {
    try {
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      await _reservationService.updateReservation(updatedReservation);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation refusée !'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du refus: $e'),
          backgroundColor: AppColors.hot,
        ),
      );
    }
  }

  Widget _buildReservationCard(Reservation reservation) {
    return GlassContainer(
      // Remplacement par GlassContainer
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.totalPrice.toStringAsFixed(1)} €',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'En attente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
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
                  style: TextStyle(fontSize: 14, color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.textWeak, size: 16),
              const SizedBox(width: 8),
              Text(
                '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                style: TextStyle(fontSize: 14, color: AppColors.textWeak),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  child: const Text('Confirmer'),
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
                  child: const Text('Refuser'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    switch (index) {
      case 0: // Accueil (déjà sur cette page)
        break;
      case 1: // Trajets
        Navigator.pushReplacementNamed(context, '/admin/trajets');
        break;
      case 2: // Gestion
        Navigator.pushReplacementNamed(context, '/admin/gestion');
        break;
      case 3: // Compte
        Navigator.pushReplacementNamed(context, '/admin/profile');
        break;
    }
  }
}
