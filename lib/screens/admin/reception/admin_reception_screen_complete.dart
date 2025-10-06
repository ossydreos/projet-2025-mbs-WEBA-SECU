import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/screens/admin/offres/admin_custom_offer_detail_screen.dart';
import 'package:my_mobility_services/data/services/admin_global_notification_service.dart';
import 'package:my_mobility_services/data/services/support_chat_service.dart';
import 'package:my_mobility_services/data/models/support_thread.dart';
import 'package:my_mobility_services/screens/support/support_chat_screen.dart';
import 'package:my_mobility_services/data/services/payment_service.dart';
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

// Énumération pour les actions de refus
enum RefusalAction { refuse, counterOffer }

class _AdminReceptionScreenState extends State<AdminReceptionScreen> {
  final ReservationService _reservationService = ReservationService();
  final AdminGlobalNotificationService _notificationService =
      AdminGlobalNotificationService();
  final CustomOfferService _customOfferService = CustomOfferService();

  // État pour suivre les réservations en cours de traitement
  final Set<String> _processingReservations = <String>{};

  // Méthode pour retirer une réservation de l'état de traitement (appelée quand le client paie)
  void removeFromProcessing(String reservationId) {
    if (mounted) {
      setState(() {
        _processingReservations.remove(reservationId);
      });
    }
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Boîte de réception',
          actions: [
            // Bulle de support
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _AdminTicketsScreen(),
                  ),
                );
              },
              child: _AdminSupportUnreadBubble(),
            ),
            const SizedBox(width: 8),
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

    // Configurer le callback pour retirer de l'état de traitement quand le paiement est effectué
    PaymentService.setPaymentCompletedCallback((reservationId) {
      removeFromProcessing(reservationId);
    });

    // Configurer le callback pour ajouter à l'état de traitement quand accepté via pop-up
    AdminGlobalNotificationService.setReservationProcessingCallback((
      reservationId,
    ) {
      // Faire exactement la même chose que _confirmReservation
      _confirmReservationFromPopup(reservationId);
    });
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
            _buildTestButton(),
            const SizedBox(height: 24),
            _buildAllPendingRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
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
            'Cliquez pour créer une réservation de test avec notification pop-up',
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications_active),
            label: const Text('🧪 Créer réservation de test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      print('🧪 Test de notification démarré');

      // Créer une réservation de test
      final testReservation = Reservation(
        id: '',
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        userName: 'Client Test',
        vehicleName: 'Berline Premium',
        departure: 'Gare de Lausanne, 1003 Lausanne',
        destination: 'Aéroport de Genève, 1215 Le Grand-Saconnex',
        selectedDate: DateTime.now().add(const Duration(hours: 2)),
        selectedTime: '14:30',
        estimatedArrival: '15:15',
        paymentMethod: 'Carte bancaire',
        totalPrice: 45.50,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        clientNote:
            'Test de notification - Cette réservation est créée pour tester le système',
      );

      print('🧪 Création de la réservation de test...');

      // Créer la réservation dans Firebase
      final reservationId = await _reservationService.createReservation(
        testReservation,
      );

      print('🧪 Réservation créée avec l\'ID: $reservationId');

      // Forcer l'affichage de la notification via le service global
      _notificationService.updateContext(context);
      _notificationService.forceShowNotification(testReservation);

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
            content: Text('❌ Erreur lors du test: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        _buildPendingReservations(),

        const SizedBox(height: 24),

        // Widget des offres personnalisées en attente
        _buildPendingCustomOffers(),
      ],
    );
  }

  Widget _buildPendingReservations() {
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
          return reservation.status == ReservationStatus.pending ||
              reservation.status == ReservationStatus.confirmed;
        }).toList();

        if (pendingReservations.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: pendingReservations
              .map((reservation) => _buildReservationCard(reservation))
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textWeak),
          const SizedBox(height: 16),
          Text(
            'Aucune demande en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouvelles demandes apparaîtront ici',
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCustomOffers() {
    return StreamBuilder<List<CustomOffer>>(
      stream: _customOfferService.getPendingCustomOffers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final offers = snapshot.data ?? <CustomOffer>[];
        if (offers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline, color: AppColors.accent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Offres personnalisées en attente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...offers.map(_buildCustomOfferCard).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCustomOfferCard(CustomOffer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.userName ?? 'Client',
                        style: TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(offer.createdAt),
                        style: TextStyle(color: AppColors.textWeak, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('En attente', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trajet
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                    Container(width: 1, height: 18, color: AppColors.textWeak.withOpacity(0.5)),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.departure, style: TextStyle(color: AppColors.text, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(offer.destination, style: TextStyle(color: AppColors.text, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Véhicule choisi par l'utilisateur (si présent)
            if ((offer.vehicleName ?? '').isNotEmpty) Row(
              children: [
                const Icon(Icons.directions_car, size: 16, color: AppColors.textWeak),
                const SizedBox(width: 8),
                Text(
                  offer.vehicleName!,
                  style: TextStyle(color: AppColors.textWeak, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (offer.clientNote != null && offer.clientNote!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.clientNote!,
                        style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminCustomOfferDetailScreen(offer: offer),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Gérer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _customOfferService.updateOfferStatus(
                          offerId: offer.id,
                          status: CustomOfferStatus.rejected,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Offre refusée'), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Refuser'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec photo de profil et actions
            Row(
              children: [
                // Photo de profil
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  child: Text(
                    reservation.userName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nom du client
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.userName ?? 'Client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                      Text(
                        _formatDate(reservation.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textWeak,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Détails du trajet
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${reservation.departure} → ${reservation.destination}',
                    style: TextStyle(fontSize: 14, color: AppColors.textStrong),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date et heure
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.textWeak, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(reservation.selectedDate)} à ${reservation.selectedTime}',
                  style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Véhicule
            Row(
              children: [
                Icon(Icons.directions_car, color: AppColors.textWeak, size: 16),
                const SizedBox(width: 8),
                Text(
                  reservation.vehicleName,
                  style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Prix
            Row(
              children: [
                Icon(Icons.euro, color: AppColors.textWeak, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${reservation.totalPrice}€',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),

            // Note du client si présente
            if (reservation.clientNote != null &&
                reservation.clientNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.clientNote!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textWeak,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

              // Bouton de contact client
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: () => _contactClient(reservation),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Contacter le client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Boutons d'action
              if (reservation.status == ReservationStatus.pending ||
                  _processingReservations.contains(reservation.id)) ...[
              // Vérifier si la réservation est en cours de traitement
              if (_processingReservations.contains(reservation.id)) ...[
                // État de chargement
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent.withOpacity(0.1),
                        AppColors.accent.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Indicateur de chargement à gauche
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Message parfaitement centré sur une seule ligne
                      Expanded(
                        child: Text(
                          'paiement client en attente',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Icône de carte à droite
                      Icon(
                        Icons.credit_card,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Demande en attente: Accepter | Contre-offre (handshake) | Refuser
                Row(
                  children: [
                    // Bouton Accepter
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _confirmReservation(reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 16),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Accepter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton Contre-offre
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _showCounterOfferDialog(reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.handshake, size: 16),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Contre-offre',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton Refuser
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _refuseReservation(reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.close, size: 16),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Refuser',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReservation(Reservation reservation) async {
    // Marquer la réservation comme en cours de traitement
    setState(() {
      _processingReservations.add(reservation.id);
    });

    try {
      // Mettre à jour le statut de la réservation
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.confirmed,
      );

      // Envoyer une notification au client pour le paiement
      await _notificationService.sendPaymentRequestNotification(
        reservation.userId,
        reservation.id,
        reservation.totalPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande de paiement envoyée au client'),
            backgroundColor: AppColors.accent,
          ),
        );
      }

      // NE PAS retirer de l'état de traitement - la bulle reste jusqu'au paiement
      // La réservation restera dans _processingReservations jusqu'à ce que le client paie
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
        // En cas d'erreur, retirer de l'état de traitement
        setState(() {
          _processingReservations.remove(reservation.id);
        });
      }
    }
  }

  // Méthode pour confirmer une réservation depuis le pop-up (même logique que _confirmReservation)
  Future<void> _confirmReservationFromPopup(String reservationId) async {
    // Marquer la réservation comme en cours de traitement
    setState(() {
      _processingReservations.add(reservationId);
    });

    try {
      // Récupérer les détails de la réservation
      final reservation = await _reservationService.getReservationById(
        reservationId,
      );
      if (reservation == null) {
        throw Exception('Réservation non trouvée');
      }

      // Mettre à jour le statut de la réservation
      await _reservationService.updateReservationStatus(
        reservationId,
        ReservationStatus.confirmed,
      );

      // Envoyer une notification au client pour le paiement
      await _notificationService.sendPaymentRequestNotification(
        reservation.userId,
        reservationId,
        reservation.totalPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande de paiement envoyée au client'),
            backgroundColor: AppColors.accent,
          ),
        );
      }

      // NE PAS retirer de l'état de traitement - la bulle reste jusqu'au paiement
      // La réservation restera dans _processingReservations jusqu'à ce que le client paie
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
        // En cas d'erreur, retirer de l'état de traitement
        setState(() {
          _processingReservations.remove(reservationId);
        });
      }
    }
  }

  Future<void> _refuseReservation(Reservation reservation) async {
    try {
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.cancelled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réservation refusée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
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
              child: const Text('Refuser', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(RefusalAction.counterOffer),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Contre-offre'),
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
                    hintText:
                        'Expliquez pourquoi vous proposez ce changement...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
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
                Navigator.of(context).pop({
                  'date': selectedDate,
                  'time': selectedTime,
                  'message': messageController.text,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Envoyer la contre-offre'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _sendCounterOffer(reservation, result);
    }
  }

  Future<void> _sendCounterOffer(
    Reservation reservation,
    Map<String, dynamic> data,
  ) async {
    try {
      // Ici vous pouvez implémenter l'envoi de la contre-offre
      // Par exemple, créer une nouvelle réservation avec le statut "counter_offer"

      // Notifications UI désactivées
    } catch (e) {
      // Notifications UI désactivées
    }
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

  // Méthode pour contacter le client
  Future<void> _contactClient(Reservation reservation) async {
    try {
      // Créer ou récupérer le thread de support pour ce client
      final thread = await _createOrGetClientThread(reservation.userId);
      
      // Naviguer vers le chat avec ce client
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportChatScreen(
            isAdmin: true,
            threadId: thread.id,
            clientName: reservation.userName,
          ),
        ),
      );
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

  // Créer ou récupérer le thread de support pour un client spécifique
  Future<SupportThread> _createOrGetClientThread(String userId) async {
    // Chercher un thread existant pour ce client
    final existing = await FirebaseFirestore.instance
        .collection(SupportChatService.threadsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final d = existing.docs.first;
      return SupportThread.fromMap(d.data(), d.id);
    }

    // Créer un nouveau thread pour ce client
    final ref = FirebaseFirestore.instance.collection(SupportChatService.threadsCollection).doc();
    final now = DateTime.now();
    final thread = SupportThread(
      id: ref.id,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      unreadForUser: 0,
      unreadForAdmin: 0,
      isClosed: false,
    );
    await ref.set(thread.toMap());
    return thread;
  }
}

class _AdminSupportUnreadBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(SupportChatService.threadsCollection)
          .where('unreadForAdmin', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snap) {
        final unread = snap.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.glass,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassStroke),
              ),
              child: const Icon(Icons.support_agent, color: Colors.white),
            ),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdminTicketsScreen extends StatelessWidget {
  const _AdminTicketsScreen();

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const GlassAppBar(
            title: 'Tickets support',
            bottom: TabBar(
              tabs: [
                Tab(text: 'En cours'),
                Tab(text: 'Terminés'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _AdminTicketsList(closed: false),
              _AdminTicketsList(closed: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTicketsList extends StatelessWidget {
  final bool closed;
  const _AdminTicketsList({required this.closed});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(SupportChatService.threadsCollection)
          .where('isClosed', isEqualTo: closed)
          .snapshots(),
      builder: (context, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final docs = s.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              closed ? 'Aucun ticket terminé' : 'Aucun ticket en cours',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final d = docs[i];
            final t = SupportThread.fromMap(d.data() as Map<String, dynamic>, d.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassContainer(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    radius: 22,
                    child: Icon(Icons.support_agent, color: Colors.white),
                  ),
                  title: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(t.userId).get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Text(
                          'Chargement...',
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        );
                      }

                      String name = _extractUserName(t);
                      if (snap.hasData && snap.data!.exists) {
                        final data = snap.data!.data() as Map<String, dynamic>;
                        final display = (data['displayName'] ?? '').toString();
                        final first = (data['firstName'] ?? '').toString();
                        final last = (data['lastName'] ?? '').toString();
                        final nameField = (data['name'] ?? '').toString();
                        final merged = (
                          nameField.isNotEmpty
                              ? nameField
                              : (display.isNotEmpty ? display : '$first $last')
                        ).trim();
                        if (merged.isNotEmpty) name = merged;
                      }
                      return Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  subtitle: Text(
                    'Mis à jour • ${_formatAdmin(t.lastMessageAt ?? t.updatedAt)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: t.unreadForAdmin > 0
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupportChatScreen(isAdmin: true, threadId: t.id),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatAdmin(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'Maintenant';
  }

  String _extractUserName(SupportThread t) {
    final uid = t.userId;
    if (uid.isEmpty) return 'Utilisateur';
    return uid.length > 6 ? 'User ${uid.substring(0, 6)}' : 'User $uid';
  }
}
