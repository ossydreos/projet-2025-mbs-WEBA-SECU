import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/admin_service.dart';
import 'package:url_launcher/url_launcher.dart';

// 👇 importe la barre réutilisable
import 'package:my_mobility_services/widgets/widget_navTrajets.dart';

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
  final AdminService _adminService = AdminService();
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
    if (index == _selectedIndex) {
      return; // Éviter la navigation si déjà sur la page
    }

    setState(() {
      _selectedIndex = index;
    });

    // Demander au shell de changer d'onglet si disponible
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: const GlassAppBar(title: 'Trajets'),

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
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (snapshot.hasError) {
          // ignore: avoid_print
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
                  SizedBox(
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
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.only(
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
                                            color: AppColors.accent,
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
                        const Positioned(
                          left: 15,
                          top: 5,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
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
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
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
                  const Text(
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
            padding: const EdgeInsets.only(bottom: 120),
            child: SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(0); // Revenir à l'onglet Accueil
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
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
                    Text(
                      reservation.vehicleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    Text(
                      reservation.statusInFrench,
                      style: TextStyle(fontSize: 12, color: AppColors.text),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  '${reservation.totalPrice.toStringAsFixed(1)} €',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.text, size: 16),
              const SizedBox(width: 8),
              Text(
                '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                style: TextStyle(fontSize: 14, color: AppColors.text),
              ),
            ],
          ),
          // Boutons de contact pour les réservations confirmées
          if (reservation.status == ReservationStatus.confirmed ||
              reservation.status == ReservationStatus.inProgress) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Appeler'),
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
                    onPressed: _sendSMS,
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(color: AppColors.accent),
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
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erreur: une erreur est survenue',
                  style: TextStyle(color: Colors.red),
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
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
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
                child: const Text(
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
                  '${reservation.departure} → ${reservation.destination}',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.text, size: 16),
              const SizedBox(width: 8),
              Text(
                '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                style: TextStyle(fontSize: 14, color: AppColors.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Lancer un appel téléphonique
  Future<void> _makePhoneCall() async {
    try {
      final phoneNumber = await _adminService.getAdminPhoneNumber();
      if (phoneNumber != null) {
        final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
        try {
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          } else {
            // Fallback: essayer de lancer directement sans vérification
            await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          // Fallback: essayer de lancer directement
          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        }
      } else {
        _showErrorSnackBar('Numéro de téléphone admin non disponible');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'appel: $e');
    }
  }

  // Envoyer un SMS
  Future<void> _sendSMS() async {
    try {
      final phoneNumber = await _adminService.getAdminPhoneNumber();
      if (phoneNumber != null) {
        final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
        try {
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
          } else {
            // Fallback: essayer de lancer directement sans vérification
            await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          // Fallback: essayer de lancer directement
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        }
      } else {
        _showErrorSnackBar('Numéro de téléphone admin non disponible');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'envoi du SMS: $e');
    }
  }

  // Afficher un message d'erreur
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.hot),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}
