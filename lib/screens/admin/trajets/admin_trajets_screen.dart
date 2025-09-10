import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/widgets/widget_navTrajets.dart';

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
  final Map<String, String> _departureAddressCache = {};

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
          // Laisse Flutter gérer la hauteur via AppBar + bottom: PreferredSize
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            titleSpacing: 16,
            title: Text(
              'Courses',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
                fontFamily: 'Poppins',
              ),
            ),
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

            // Place proprement le TabBar dans AppBar.bottom
            bottom: TrajetNav(_tabController),
          ),

          // Le contenu occupe l’espace restant, sans Column supplémentaire.
          body: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [_buildUpcomingTab(), _buildCompletedTab()],
          ),

          // Bonne pratique: placer la navbar ici
          bottomNavigationBar: AdminBottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _handleNavigation,
          ),
        ),
      ),
    );
  }

  String _formatAddress(String label, Map<String, dynamic>? coords) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'ma position actuelle' && coords != null) {
      final lat = (coords['latitude'] as num?)?.toDouble();
      final lng = (coords['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return 'Position GPS (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
      }
    }
    return label;
  }

  String _getDepartureText(Reservation reservation) {
    final label = reservation.departure;
    final normalized = label.trim().toLowerCase();
    if (normalized != 'ma position actuelle') return label;

    final coords = reservation.departureCoordinates;
    if (coords == null) return label; // pas d'info en base

    final key = reservation.id.isNotEmpty
        ? reservation.id
        : '${coords['latitude']}_${coords['longitude']}';
    final cached = _departureAddressCache[key];
    if (cached != null && cached.isNotEmpty) return cached;

    final lat = (coords['latitude'] as num?)?.toDouble();
    final lng = (coords['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return label;

    _resolveAndCacheAddress(key, lat, lng);
    return _formatAddress(label, coords);
  }

  Future<void> _resolveAndCacheAddress(
    String key,
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        lat,
        lng,
        localeIdentifier: 'fr_FR',
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = p.street?.trim();
        final postal = p.postalCode?.trim();
        final city = p.locality?.trim();
        final parts = [
          street,
          postal,
          city,
        ].where((s) => s != null && s!.isNotEmpty).cast<String>().toList();
        final formatted = parts.isNotEmpty ? parts.join(' ') : 'Position GPS';
        if (mounted) {
          setState(() {
            _departureAddressCache[key] = formatted;
          });
        } else {
          _departureAddressCache[key] = formatted;
        }
      }
    } catch (_) {
      // on garde le fallback
    }
  }

  Widget _buildUpcomingTab() {
    // On peut ajouter un SafeArea(bottom:false) au besoin, mais ici pas nécessaire
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getConfirmedReservationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: GlassContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.hot),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: AppColors.hot),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final confirmedReservations = snapshot.data ?? [];

        if (confirmedReservations.isEmpty) {
          // Pas de scroll obligatoire: Center suffit
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildEmptyUpcomingView(),
          );
        }

        // Ajoute un padding bas qui tient compte de la hauteur de la bottomNavigationBar
        final bottomPad =
            MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
          physics: const BouncingScrollPhysics(),
          itemCount: confirmedReservations.length,
          itemBuilder: (context, index) {
            final reservation = confirmedReservations[index];
            return _buildConfirmedReservationCard(reservation);
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
            child: CircularProgressIndicator(color: AppColors.accent),
          );
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: GlassContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.hot),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: AppColors.hot),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final completedReservations = snapshot.data ?? [];

        if (completedReservations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildEmptyCompletedView(),
          );
        }

        final bottomPad =
            MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
          physics: const BouncingScrollPhysics(),
          itemCount: completedReservations.length,
          itemBuilder: (context, index) {
            final reservation = completedReservations[index];
            return _buildCompletedReservationCard(reservation);
          },
        );
      },
    );
  }

  Widget _buildEmptyUpcomingView() {
    return Center(
      child: GlassContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 64, color: AppColors.textWeak),
            const SizedBox(height: 16),
            Text(
              'Aucun trajet à venir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les prochains trajets apparaîtront ici',
              style: TextStyle(fontSize: 14, color: AppColors.textWeak),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCompletedView() {
    return Center(
      child: GlassContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textWeak),
            const SizedBox(height: 16),
            Text(
              'Aucun trajet terminé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les trajets terminés apparaîtront ici',
              style: TextStyle(fontSize: 14, color: AppColors.textWeak),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedReservationCard(Reservation reservation) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
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
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
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
                    Flexible(
                      child: Text(
                        '${reservation.totalPrice.toStringAsFixed(1)} €',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.accent2,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'Confirmée',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
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
                  '${_getDepartureText(reservation)} → ${reservation.destination}',
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
          // Affichage de la note du client si elle existe
          if (reservation.clientNote != null && reservation.clientNote!.isNotEmpty) ...[
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
                  Icon(
                    Icons.note_alt,
                    color: AppColors.accent,
                    size: 16,
                  ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _completeReservation(reservation),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Terminée'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(reservation),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.hot,
                    side: BorderSide(color: AppColors.hot),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedReservationCard(Reservation reservation) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
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
                    Flexible(
                      child: Text(
                        '${reservation.totalPrice.toStringAsFixed(1)} €',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.accent2,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'Terminée',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
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
                  '${_getDepartureText(reservation)} → ${reservation.destination}',
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
          // Affichage de la note du client si elle existe
          if (reservation.clientNote != null && reservation.clientNote!.isNotEmpty) ...[
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
                  Icon(
                    Icons.note_alt,
                    color: AppColors.accent,
                    size: 16,
                  ),
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
        ],
      ),
    );
  }

  void _showCancelDialog(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(158, 11, 14, 19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.glassStroke),
          ),
          title: Text(
            'Annuler la réservation',
            style: TextStyle(color: AppColors.textStrong),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir annuler cette réservation ?',
            style: TextStyle(color: AppColors.text),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textWeak,
                side: BorderSide(color: AppColors.glassStroke, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelConfirmedReservation(reservation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hot,
                foregroundColor: Colors.white,
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
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

  Future<void> _completeReservation(Reservation reservation) async {
    try {
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.completed,
        updatedAt: DateTime.now(),
      );
      await _reservationService.updateReservation(updatedReservation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course marquée comme terminée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.hot),
        );
      }
    }
  }

  Future<void> _cancelConfirmedReservation(Reservation reservation) async {
    try {
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.cancelled,
        updatedAt: DateTime.now(),
      );
      await _reservationService.updateReservation(updatedReservation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course annulée !'),
            backgroundColor: AppColors.hot,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.hot),
        );
      }
    }
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
