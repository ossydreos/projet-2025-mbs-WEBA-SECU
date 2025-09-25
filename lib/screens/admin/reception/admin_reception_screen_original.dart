import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/admin_global_notification_service.dart';
import 'package:my_mobility_services/data/services/reservation_timeout_service.dart';
import 'package:my_mobility_services/widgets/admin/pending_reservations_widget.dart';
import '../../../l10n/generated/app_localizations.dart';

class AdminReceptionScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const AdminReceptionScreen({
    super.key,
    this.onNavigate,
    this.showBottomBar = true,
  });

  @override
  State<AdminReceptionScreen> createState() => _AdminReceptionScreenState();
}

class _AdminReceptionScreenState extends State<AdminReceptionScreen> {
  final ReservationService _reservationService = ReservationService();
  final AdminGlobalNotificationService _notificationService =
      AdminGlobalNotificationService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Boîte de réception',
          actions: [
            // Bouton pour annuler toutes les réservations en attente de paiement
            IconButton(
              onPressed: _cancelAllWaitingReservations,
              icon: Icon(Icons.clear_all, color: Colors.red),
              tooltip: 'Annuler toutes les réservations en attente',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildContent()),
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

  @override
  void initState() {
    super.initState();
    // Initialiser le service de notifications
    _notificationService.initialize(context);
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
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
            _buildAllPendingRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
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

        final pendingCount = reservations
            .where((r) => r.status == ReservationStatus.pending)
            .length;
        final confirmedCount = reservations
            .where((r) => r.status == ReservationStatus.confirmed)
            .length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'En attente',
                pendingCount.toString(),
                Icons.pending,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Confirmées',
                confirmedCount.toString(),
                Icons.check_circle,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Méthode pour annuler toutes les réservations en attente de paiement
  Future<void> _cancelAllWaitingReservations() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Annuler toutes les réservations en attente',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir annuler toutes les réservations en attente de paiement ?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      // Récupérer toutes les réservations en attente de paiement
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.confirmed.name)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).noReservationsWaitingPayment,
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Annuler toutes les réservations en batch
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': ReservationStatus.cancelled.name,
          'lastUpdated': Timestamp.now(),
          'cancelledAt': Timestamp.now(),
          'cancelledBy': 'admin',
          'cancellationReason': 'Annulé par l\'admin (debug)',
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).reservationsCancelledSuccess(querySnapshot.docs.length),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).errorCancelling(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    switch (index) {
      case 0: // Demandes
        Navigator.pushReplacementNamed(context, '/admin/home');
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

  Widget _buildAllPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête unifié
        Row(
          children: [
            Icon(Icons.inbox, color: AppColors.accent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Demandes en attente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Widget des réservations en attente
        const PendingReservationsWidget(),
      ],
    );
  }
}
