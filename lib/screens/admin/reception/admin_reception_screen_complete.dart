import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/admin_global_notification_service.dart';
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
                // Bouton de mise en attente (petite croix)
                IconButton(
                  onPressed: () => _putInWaiting(reservation),
                  icon: Icon(Icons.close, color: Colors.orange, size: 20),
                  tooltip: 'Mettre en attente',
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

            // Boutons d'action
            if (reservation.status == ReservationStatus.pending) ...[
              // Demande en attente: Accepter | Contre-offre (handshake) | Refuser
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmReservation(reservation),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCounterOfferDialog(reservation),
                      icon: const Icon(Icons.handshake, size: 16),
                      label: const Text('Contre-offre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _refuseReservation(reservation),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Refuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Autres statuts: Accepter | Refuser | Contre-offre (swap)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmReservation(reservation),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _refuseReservation(reservation),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Refuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCounterOfferDialog(reservation),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Contre-offre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Future<void> _confirmReservation(Reservation reservation) async {
    try {
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.confirmed,
      );

      // Notifications UI désactivées
    } catch (e) {
      // Notifications UI désactivées
    }
  }

  Future<void> _refuseReservation(Reservation reservation) async {
    final action = await _showRefusalDialog();

    switch (action) {
      case RefusalAction.refuse:
        try {
          await _reservationService.updateReservationStatus(
            reservation.id,
            ReservationStatus.cancelled,
          );

          // Notifications UI désactivées
        } catch (e) {
          // Notifications UI désactivées
        }
        break;
      case RefusalAction.counterOffer:
        _showCounterOfferDialog(reservation);
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

  Future<void> _putInWaiting(Reservation reservation) async {
    try {
      // Mettre la réservation en attente (statut pending)
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.pending,
      );

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
}
