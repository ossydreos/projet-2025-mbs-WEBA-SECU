import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;


  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Boîte de réception',
          actions: [
            // Bouton de test pour créer des réservations
            IconButton(
              onPressed: _createTestReservation,
              icon: Icon(Icons.science, color: AppColors.accent),
              tooltip: 'Créer réservation de test',
            ),
            // Bouton pour annuler toutes les réservations en attente de paiement
            IconButton(
              onPressed: _cancelAllWaitingReservations,
              icon: Icon(Icons.clear_all, color: Colors.red),
              tooltip: 'Annuler toutes les réservations en attente',
            ),
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
            style: TextStyle(fontSize: 12, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réservations en cours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reservations')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur de chargement: ${snapshot.error}',
                  style: TextStyle(color: AppColors.hot),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final allReservations = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Reservation.fromMap({...data, 'id': doc.id});
            }).toList();

            // Debug logs supprimés pour éviter le spam

        // Filtrer côté client pour éviter les problèmes d'index Firestore
        // Prendre toutes les réservations en attente ET toutes les confirmations (normales + contre-offres)
        // Exclure les réservations inProgress (déjà payées)
        final reservations = allReservations
            .where((r) => r.status == ReservationStatus.pending ||
                         r.status == ReservationStatus.confirmed)
            .toList();


            if (reservations.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReservationCard(reservations[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.white.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Aucune réservation en cours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouvelles réservations et celles en attente de paiement apparaîtront ici',
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final hasCounterOffer = reservation.hasCounterOffer ?? false;

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
                    '${(reservation.totalPrice ?? 0.0).toStringAsFixed(2)}€',
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
                  // Afficher l'heure avec contre-offre si applicable
                  if (reservation.hasCounterOffer && reservation.driverProposedTime != null) ...[
                    Builder(
                      builder: (context) {
                        final timeChanged = reservation.selectedTime != reservation.driverProposedTime;
                        
                        if (timeChanged) {
                          return Row(
                            children: [
                              Text(
                                reservation.selectedTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWeak,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: AppColors.accent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                reservation.driverProposedTime!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Text(
                            reservation.selectedTime,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          );
                        }
                      },
                    ),
                  ] else ...[
                    Text(
                      reservation.selectedTime,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Arrivée',
                    style: TextStyle(fontSize: 12, color: AppColors.textWeak),
                  ),
                  // Afficher l'heure d'arrivée avec contre-offre si applicable
                  if (reservation.hasCounterOffer && reservation.driverProposedTime != null) ...[
                    Builder(
                      builder: (context) {
                        final timeChanged = reservation.selectedTime != reservation.driverProposedTime;
                        
                        if (timeChanged) {
                          // Calculer la nouvelle heure d'arrivée basée sur la nouvelle heure de départ
                          final newArrivalTime = _calculateArrivalTime(
                            reservation.driverProposedTime!,
                            reservation.estimatedArrival,
                            reservation.selectedTime,
                          );
                          
                          return Row(
                            children: [
                              Text(
                                reservation.estimatedArrival ?? '--:--',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWeak,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: AppColors.accent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                newArrivalTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Text(
                            reservation.estimatedArrival ?? '--:--',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          );
                        }
                      },
                    ),
                  ] else ...[
                    Text(
                      reservation.estimatedArrival ?? '--:--',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date et mode de paiement
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.textWeak, size: 16),
              const SizedBox(width: 8),
              // Afficher la date avec contre-offre si applicable
              if (reservation.hasCounterOffer && reservation.driverProposedDate != null) ...[
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
                    final dateChanged = !selectedDateOnly.isAtSameMomentAs(proposedDateOnly);
                    
                    if (dateChanged) {
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
                          const Icon(Icons.arrow_forward, color: AppColors.accent, size: 16),
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
                        style: TextStyle(fontSize: 14, color: AppColors.textWeak),
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

          // Affichage de la note du client si elle existe
          if (reservation.clientNote != null &&
              reservation.clientNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reservation.clientNote!,
                          style: TextStyle(fontSize: 14, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // *** Affichage de la contre-offre si elle existe ***
          if (hasCounterOffer) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Contre-offre proposée',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NOUVEAU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reservation.adminMessage != null &&
                      reservation.adminMessage!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      reservation.adminMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Boutons d'action ou barre d'attente
          if (reservation.status == ReservationStatus.confirmed) ...[
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
                  Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 24,
                  ),
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

  // Méthode pour annuler toutes les réservations en attente de paiement
  Future<void> _cancelAllWaitingReservations() async {
    // Demander confirmation
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Annuler toutes les réservations',
      message: 'Êtes-vous sûr de vouloir annuler toutes les réservations en attente de paiement ? Cette action est irréversible.',
      confirmText: 'Oui, annuler tout',
      cancelText: 'Non',
      icon: Icons.cancel_outlined,
      iconColor: Colors.redAccent,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (confirmed != true) return;

    try {
      // Récupérer toutes les réservations en attente de paiement
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: ReservationStatus.confirmed.name)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune réservation en attente de paiement à annuler'),
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
          'status': 'cancelled',
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
            content: Text('${querySnapshot.docs.length} réservation(s) annulée(s) avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour créer une réservation de test
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
        selectedDate: DateTime.now().add(const Duration(days: 1)),
        selectedTime:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        estimatedArrival:
            '${now.hour.toString().padLeft(2, '0')}:${(now.minute + 13).toString().padLeft(2, '0')}',
        paymentMethod: 'Espèces',
        totalPrice: 6.0,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        clientNote: 'Test de réservation avec note client',
      );

      await _reservationService.createReservation(testReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation de test créée avec succès !'),
            backgroundColor: Colors.green,
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

  Future<void> _confirmReservation(Reservation reservation) async {
    try {
      // Mettre à jour le statut vers confirmed
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.confirmed,
      );


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation confirmée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ AJOUT : Petit délai pour laisser Firestore se synchroniser
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final action = await _showRefusalDialog();
    if (action == null) return;

    switch (action) {
      case RefusalAction.refuse:
        await _refuseReservation(reservation);
        break;
      case RefusalAction.counterOffer:
        await _showCounterOfferDialog(reservation);
        break;
    }
  }

  Future<RefusalAction?> _showRefusalDialog() async {
    return showDialog<RefusalAction>(
      context: context,
      builder: (BuildContext context) {
        return GlassActionDialog(
          title: 'Action sur la réservation',
          message: 'Que souhaitez-vous faire avec cette réservation ?',
          actions: [
            GlassActionButton(
              label: 'Annuler',
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.textWeak,
            ),
            GlassActionButton(
              label: 'Refuser',
              onPressed: () => Navigator.of(context).pop(RefusalAction.refuse),
              icon: Icons.close,
              color: Colors.red,
            ),
            GlassActionButton(
              label: 'Contre-offre',
              onPressed: () => Navigator.of(context).pop(RefusalAction.counterOffer),
              icon: Icons.handshake,
              color: AppColors.accent,
              isPrimary: true,
            ),
          ],
        );
      },
    );
  }

  Future<void> _refuseReservation(Reservation reservation) async {
    try {
      final updatedReservation = Reservation(
        id: reservation.id,
        userId: reservation.userId,
        userName: reservation.userName,
        vehicleName: reservation.vehicleName,
        departure: reservation.departure,
        destination: reservation.destination,
        selectedDate: reservation.selectedDate,
        selectedTime: reservation.selectedTime,
        estimatedArrival: reservation.estimatedArrival,
        paymentMethod: reservation.paymentMethod,
        totalPrice: reservation.totalPrice,
        status: ReservationStatus.cancelled,
        createdAt: reservation.createdAt,
        clientNote: reservation.clientNote,
      );

      await _reservationService.updateReservation(updatedReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
          title: Text(
            'Proposer une nouvelle date/heure',
            style: TextStyle(color: AppColors.textStrong),
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
                    color: AppColors.glass.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassStroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date/heure actuelle:',
                        style: TextStyle(
                          color: AppColors.textWeak,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reservation.selectedDate.day}/${reservation.selectedDate.month}/${reservation.selectedDate.year} à ${reservation.selectedTime}',
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nouvelle date
                Text(
                  'Nouvelle date:',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020), // Date très ancienne pour permettre toutes les dates
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent,
                              onPrimary: Colors.white,
                              surface: AppColors.bgElev,
                              onSurface: Colors.white,
                              secondary: AppColors.accent,
                              onSecondary: Colors.white,
                            ),
                            dialogBackgroundColor: AppColors.bgElev,
                            cardColor: AppColors.bgElev,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nouvelle heure
                Text(
                  'Nouvelle heure:',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent,
                              onPrimary: Colors.white,
                              surface: AppColors.bgElev,
                              onSurface: Colors.white,
                              secondary: AppColors.accent,
                              onSecondary: Colors.white,
                            ),
                            dialogBackgroundColor: AppColors.bgElev,
                            cardColor: AppColors.bgElev,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message/commentaire
                Text(
                  'Commentaire pour le client:',
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Expliquez le motif du changement d\'horaire...',
                    hintStyle: TextStyle(color: AppColors.textWeak),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.glass.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textWeak),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Proposer'),
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

  // Méthode mise à jour pour gérer date/heure + commentaire
  Future<void> _sendCounterOffer(
    Reservation reservation,
    DateTime newDate,
    String newTime,
    String message,
  ) async {
    try {
      // 🔥 Mettre à jour directement la réservation avec les détails de la contre-offre
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservation.id)
          .update({
        'hasCounterOffer': true, // Indique qu'une contre-offre a été proposée
        'driverProposedDate': Timestamp.fromDate(DateTime.utc(newDate.year, newDate.month, newDate.day)), // Date proposée par le chauffeur
        'driverProposedTime': newTime, // Heure proposée par le chauffeur
        'adminMessage': message, // Message de l'admin
        'status': ReservationStatus.confirmed.name, // Confirmée avec contre-offre
        'lastUpdated': Timestamp.now(),
      });

      // 🔍 DEBUG: Vérifier que la mise à jour a bien eu lieu
      print('🔥 Contre-offre envoyée pour réservation ${reservation.id}');
      print('🔥 Statut mis à jour vers: ${ReservationStatus.confirmed.name}');
      print('🔥 Champ hasCounterOffer mis à: true');
      print('🔥 Date proposée: ${newDate.day}/${newDate.month} à $newTime');


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Contre-offre envoyée: ${newDate.day}/${newDate.month} à $newTime',
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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

  // Calculer la nouvelle heure d'arrivée basée sur la nouvelle heure de départ
  String _calculateArrivalTime(String newDepartureTime, String originalArrivalTime, String originalDepartureTime) {
    try {
      // Parser les heures originales
      final originalDepartureParts = originalDepartureTime.split(':');
      final originalArrivalParts = originalArrivalTime.split(':');
      
      if (originalDepartureParts.length != 2 || originalArrivalParts.length != 2) {
        return originalArrivalTime; // Retourner l'original si format invalide
      }
      
      final originalDepartureHour = int.parse(originalDepartureParts[0]);
      final originalDepartureMinute = int.parse(originalDepartureParts[1]);
      final originalArrivalHour = int.parse(originalArrivalParts[0]);
      final originalArrivalMinute = int.parse(originalArrivalParts[1]);
      
      // Calculer la durée du trajet en minutes
      final originalDepartureMinutes = originalDepartureHour * 60 + originalDepartureMinute;
      final originalArrivalMinutes = originalArrivalHour * 60 + originalArrivalMinute;
      final tripDurationMinutes = originalArrivalMinutes - originalDepartureMinutes;
      
      // Parser la nouvelle heure de départ
      final newDepartureParts = newDepartureTime.split(':');
      if (newDepartureParts.length != 2) {
        return originalArrivalTime; // Retourner l'original si format invalide
      }
      
      final newDepartureHour = int.parse(newDepartureParts[0]);
      final newDepartureMinute = int.parse(newDepartureParts[1]);
      
      // Calculer la nouvelle heure d'arrivée
      final newDepartureMinutes = newDepartureHour * 60 + newDepartureMinute;
      final newArrivalMinutes = newDepartureMinutes + tripDurationMinutes;
      
      // Convertir en heures et minutes
      final newArrivalHour = (newArrivalMinutes ~/ 60) % 24;
      final newArrivalMinute = newArrivalMinutes % 60;
      
      // Formater l'heure
      return '${newArrivalHour.toString().padLeft(2, '0')}:${newArrivalMinute.toString().padLeft(2, '0')}';
    } catch (e) {
      return originalArrivalTime; // Retourner l'original en cas d'erreur
    }
  }
}
