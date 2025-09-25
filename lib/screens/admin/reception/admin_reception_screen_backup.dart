import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/data/services/admin_global_notification_service.dart';
import 'package:my_mobility_services/widgets/admin/pending_reservations_widget.dart';
import '../offres/admin_custom_offer_detail_screen.dart';
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

// Ã‰numÃ©ration pour les actions de refus
enum RefusalAction { refuse, counterOffer }

class _AdminReceptionScreenState extends State<AdminReceptionScreen> {
  final ReservationService _reservationService = ReservationService();
  final CustomOfferService _customOfferService = CustomOfferService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'BoÃ®te de rÃ©ception',
          actions: [
            // Bouton pour annuler toutes les rÃ©servations en attente de paiement
            IconButton(
              onPressed: _cancelAllWaitingReservations,
              icon: Icon(Icons.clear_all, color: Colors.red),
              tooltip: 'Annuler toutes les rÃ©servations en attente',
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
    // Les notifications sont maintenant gÃ©rÃ©es globalement par AdminScreenWrapper
  }

  @override
  void dispose() {
    // Les notifications sont maintenant gÃ©rÃ©es globalement
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
            _buildTestNotificationButton(),
            const SizedBox(height: 24),
            _buildAllPendingRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Test des notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cliquez pour tester l\'affichage des notifications pop-up',
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('ðŸ§ª Tester'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checkPendingReservations,
                  icon: const Icon(Icons.search),
                  label: const Text('ðŸ” VÃ©rifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _debugNotificationService,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('🐛 Debug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _forceNotificationCheck,
                  icon: const Icon(Icons.refresh),
                  label: const Text('🔄 Forcer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      print('ðŸ§ª Test de notification dÃ©marrÃ©');

      // CrÃ©er une rÃ©servation de test
      final testReservation = Reservation(
        id: '',
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        userName: 'Client Test',
        vehicleName: 'Berline Premium',
        departure: 'Gare de Lausanne, 1003 Lausanne',
        destination: 'AÃ©roport de GenÃ¨ve, 1215 Le Grand-Saconnex',
        selectedDate: DateTime.now().add(const Duration(hours: 2)),
        selectedTime: '14:30',
        estimatedArrival: '15:15',
        paymentMethod: 'Carte bancaire',
        totalPrice: 45.50,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        clientNote:
            'Test de notification - Cette rÃ©servation est crÃ©Ã©e pour tester le systÃ¨me',
      );

      print('ðŸ§ª CrÃ©ation de la rÃ©servation de test...');

      // CrÃ©er la rÃ©servation dans Firebase
      final reservationId = await _reservationService.createReservation(
        testReservation,
      );

      print('🧪 Réservation créée avec l\'ID: $reservationId');

      // Forcer l'affichage de la notification via le service global
      final adminNotificationService = AdminGlobalNotificationService();
      adminNotificationService.updateContext(context);
      adminNotificationService.forceShowNotification(testReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Notification de test affichée ! Réservation: ${reservationId.substring(0, 8)}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('🧪 Erreur lors du test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âŒ Erreur lors du test: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkPendingReservations() async {
    try {
      print('ðŸ” VÃ©rification des rÃ©servations en attente...');

      final adminNotificationService = AdminGlobalNotificationService();
      await adminNotificationService.checkPendingReservations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ðŸ” VÃ©rification des rÃ©servations en attente effectuÃ©e',
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('ðŸ” Erreur lors de la vÃ©rification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âŒ Erreur lors de la vÃ©rification: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _debugNotificationService() {
    final adminNotificationService = AdminGlobalNotificationService();
    adminNotificationService.debugServiceState();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐛 État du service affiché dans la console'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _forceNotificationCheck() {
    final adminNotificationService = AdminGlobalNotificationService();
    adminNotificationService.forceCheckNewReservations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Vérification forcée des notifications'),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
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

        // Compter les réservations en attente d'action admin (pending + confirmed)
        final pendingCount = reservations
            .where((r) => r.status == ReservationStatus.pending)
            .length;
        final confirmedCount = reservations
            .where((r) => r.status == ReservationStatus.confirmed)
            .length;

        // Total des demandes en attente d'action admin
        final totalPending = pendingCount + confirmedCount;

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
                'Total demandes',
                totalPending.toString(),
                Icons.inbox,
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
            style: TextStyle(fontSize: 12, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // MÃ©thode pour annuler toutes les rÃ©servations en attente de paiement
  Future<void> _cancelAllWaitingReservations() async {
    // Demander confirmation
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: AppLocalizations.of(context).cancelAllReservations,
      message:
          'ÃŠtes-vous sÃ»r de vouloir annuler toutes les rÃ©servations en attente de paiement ? Cette action est irrÃ©versible.',
      confirmText: 'Oui, annuler tout',
      cancelText: 'Non',
      icon: Icons.cancel_outlined,
      iconColor: Colors.redAccent,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (confirmed != true) return;

    try {
      // RÃ©cupÃ©rer toutes les rÃ©servations en attente de paiement
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

      // Annuler toutes les rÃ©servations en batch
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'lastUpdated': Timestamp.now(),
          'cancelledAt': Timestamp.now(),
          'cancelledBy': 'admin',
          'cancellationReason': 'AnnulÃ© par l\'admin (debug)',
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

  // MÃ©thode mise Ã  jour pour gÃ©rer date/heure + commentaire

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
      case 0: // Accueil (dÃ©jÃ  sur cette page)
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

  // Calculer la nouvelle heure d'arrivÃ©e basÃ©e sur la nouvelle heure de dÃ©part

  Widget _buildAllPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tÃªte unifiÃ©
        Row(
          children: [
            const Icon(Icons.inbox, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            Text(
              'Demandes en attente',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Widget des rÃ©servations en attente
        const PendingReservationsWidget(),

        // Offres personnalisÃ©es en attente
        StreamBuilder<QuerySnapshot>(
          stream: _customOfferService.getCustomOffersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink(); // Pas de loading pour les offres
            }

            if (snapshot.hasError) {
              return const SizedBox.shrink(); // Pas d'erreur visible pour les offres
            }

            final offers =
                snapshot.data?.docs
                    .map(
                      (doc) => CustomOffer.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList() ??
                [];

            print('Admin - Total offres trouvÃ©es: ${offers.length}');
            for (final offer in offers) {
              print('Admin - Offre ${offer.id}: statut = ${offer.status.name}');
            }

            // Filtrer seulement les offres en attente
            final pendingOffers = offers
                .where((o) => o.status == CustomOfferStatus.pending)
                .toList();

            print(
              'Admin - Offres en attente aprÃ¨s filtrage: ${pendingOffers.length}',
            );

            // FORCER LE FILTRAGE - NE PAS AFFICHER LES OFFRES ANNULEES
            final validOffers = offers
                .where(
                  (o) =>
                      o.status == CustomOfferStatus.pending ||
                      o.status == CustomOfferStatus.accepted,
                )
                .toList();

            print(
              'Admin - Offres valides (pending/accepted): ${validOffers.length}',
            );

            if (validOffers.isEmpty) {
              print('Admin - Aucune offre valide Ã  afficher');
              return const SizedBox.shrink();
            }

            print('Admin - Affichage de ${validOffers.length} offres valides');
            return Column(
              children: [
                const SizedBox(height: 16),
                ...validOffers.map((offer) => _buildCustomOfferCard(offer)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomOfferCard(CustomOffer offer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: InkWell(
          onTap: () => _openCustomOfferDetail(offer),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tÃªte avec statut et date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'En attente',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatDate(offer.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Trajet
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${offer.departure} â†’ ${offer.destination}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // DurÃ©e
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${offer.durationHours}h ${offer.durationMinutes}min',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                // Note du client (si prÃ©sente)
                if (offer.clientNote != null &&
                    offer.clientNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offer.clientNote!,
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }

  void _openCustomOfferDetail(CustomOffer offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCustomOfferDetailScreen(offer: offer),
      ),
    );
  }
}
