import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';

class TrajetsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const TrajetsScreen({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<TrajetsScreen> createState() => _TrajetsScreenState();
}

class _TrajetsScreenState extends State<TrajetsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _selectedIndex = 1; // Index 1 pour "Trajets" (actif)
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  void _onItemTapped(int index) {
    if (index == _selectedIndex)
      return; // Éviter la navigation si déjà sur la page

    setState(() {
      _selectedIndex = index;
    });

    // Navigation vers les autres écrans
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    } else {
      switch (index) {
        case 0: // Accueil
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1: // Trajets (déjà sur cette page)
          break;
        case 2: // Compte
          Navigator.pushReplacementNamed(context, '/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(title: 'Trajets'),
        body: SafeArea(
          child: Column(
            children: [
              // Onglets
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  indicatorColor: Brand.accent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                  tabs: const [
                    Tab(text: 'À venir'),
                    Tab(text: 'Terminés'),
                  ],
                ),
              ),

              // Contenu principal
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet "À venir"
                    _buildUpcomingTab(),
                    // Onglet "Terminés"
                    _buildCompletedTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: widget.showBottomBar
            ? CustomBottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              )
            : null,
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return _buildNotLoggedInView();
    }

    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getUserConfirmedReservationsStream(),
      initialData: const [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Brand.accent),
          );
        }

        if (snapshot.hasError) {
          print('Erreur dans trajets_screen: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur de connexion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.red[300]),
                  ),
                ),
                const SizedBox(height: 24),
                GlassButton(
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
        final upcomingReservations = reservations
            .where(
              (r) =>
                  r.status == ReservationStatus.pending ||
                  r.status == ReservationStatus.confirmed ||
                  r.status == ReservationStatus.inProgress,
            )
            .toList();

        if (upcomingReservations.isEmpty) {
          return _buildEmptyUpcomingView();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingReservations.length,
          itemBuilder: (context, index) {
            final reservation = upcomingReservations[index];
            return _buildReservationCard(reservation);
          },
        );
      },
    );
  }

  Widget _buildNotLoggedInView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Connectez-vous pour voir vos réservations',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcomingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Contenu principal centré
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration 3D du calendrier
                  Container(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        // Calendrier de base
                        Positioned(
                          left: 20,
                          top: 10,
                          child: Container(
                            width: 80,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Barre supérieure du calendrier
                                Container(
                                  height: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                // Grille du calendrier
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(4),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 7,
                                          childAspectRatio: 1,
                                          crossAxisSpacing: 2,
                                          mainAxisSpacing: 2,
                                        ),
                                    itemCount: 35,
                                    itemBuilder: (context, index) {
                                      // Carré vert mis en évidence
                                      if (index == 15) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Brand.accent,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        );
                                      }
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Anneau de reliure
                        Positioned(
                          left: 15,
                          top: 5,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Icône d'horloge verte
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Brand.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Brand.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Message principal en anglais
                  Text(
                    'No Upcoming rides',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Message secondaire en français
                  Text(
                    'Emploi du temps compliqué? Optez pour un trajet planifié pour arriver à l\'heure.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      height: 1.4,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bouton d'action en bas
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                label: 'Planifiez un trajet',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: Brand.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Brand.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.vehicleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Brand.textStrong,
                      ),
                    ),
                    Text(
                      reservation.statusInFrench,
                      style: TextStyle(fontSize: 12, color: Brand.text),
                    ),
                  ],
                ),
              ),
              Text(
                '${reservation.totalPrice.toStringAsFixed(1)} €',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Brand.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Brand.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${reservation.departure} → ${reservation.destination}',
                  style: const TextStyle(fontSize: 14, color: Brand.textStrong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: Brand.text, size: 16),
              const SizedBox(width: 8),
              Text(
                '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                style: TextStyle(fontSize: 14, color: Brand.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return _buildNotLoggedInView();
    }

    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getUserCompletedReservationsStream(),
      initialData: const [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Brand.accent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final reservations = snapshot.data ?? [];
        final completedReservations = reservations
            .where((r) => r.status == ReservationStatus.completed)
            .toList();

        if (completedReservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'Aucun trajet terminé',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[400],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedReservations.length,
          itemBuilder: (context, index) {
            final reservation = completedReservations[index];
            return _buildCompletedReservationCard(reservation);
          },
        );
      },
    );
  }

  Widget _buildCompletedReservationCard(Reservation reservation) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.vehicleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.totalPrice.toStringAsFixed(1)} €',
                      style: TextStyle(
                        fontSize: 14,
                        color: Brand.accent,
                        fontWeight: FontWeight.w600,
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
              Icon(Icons.location_on, color: Brand.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${reservation.departure} → ${reservation.destination}',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: Brand.text, size: 16),
              const SizedBox(width: 8),
              Text(
                '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                style: TextStyle(fontSize: 14, color: Brand.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
