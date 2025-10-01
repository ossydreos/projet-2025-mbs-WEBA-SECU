import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/models/reservation_filter.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/admin_service.dart';
import 'package:my_mobility_services/data/services/pdf_export_service.dart';
import 'package:my_mobility_services/widgets/admin/reservation_filter_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/generated/app_localizations.dart';

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

  // Variables pour le filtrage avancé
  ReservationFilter _upcomingFilter = const ReservationFilter(isUpcoming: true);
  ReservationFilter _completedFilter = const ReservationFilter(
    isUpcoming: false,
  );

  // Variables pour l'export
  List<Reservation> _currentReservations = [];

  // Variables pour la sélection directe
  bool _isSelectionMode = false;
  Set<String> _selectedReservations = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  bool get wantKeepAlive => true;

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

    widget.onNavigate?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: GlassAppBar(
          title: _isSelectionMode
              ? 'Sélectionner les courses (${_selectedReservations.length})'
              : AppLocalizations.of(context).trips,
          actions: _isSelectionMode
              ? _buildSelectionActions()
              : _buildNormalActions(),
        ),

        body: Column(
          children: [
            // Barre de navigation des onglets séparée
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TrajetNav(_tabController),
            ),
            // Filtrage/tri déclenchés depuis le menu (comme admin)
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

        bottomNavigationBar: _isSelectionMode
            ? _buildSelectionBottomBar()
            : (widget.showBottomBar
                  ? CustomBottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                    )
                  : null),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return _buildNotLoggedInView();
    }

    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getUserUpcomingReservationsStreamWithFilter(
        currentUser.uid,
        _upcomingFilter,
      ),
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

        // Mettre à jour les réservations actuelles pour l'export
        _currentReservations = reservations;

        if (reservations.isEmpty) {
          return _buildEmptyUpcomingView();
        }

        return Column(
          children: [
            // Indicateur du nombre de résultats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${reservations.length} résultat${reservations.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Liste des réservations
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];
                  return _buildReservationCard(reservation);
                },
              ),
            ),
          ],
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
    final hasActiveFilter = _upcomingFilter.hasActiveFilter;

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

                  // Message principal
                  Text(
                    hasActiveFilter ? 'Aucun résultat' : 'No Upcoming rides',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Message secondaire
                  Text(
                    hasActiveFilter
                        ? 'Aucun trajet à venir ne correspond à vos filtres. Essayez de modifier vos critères de recherche.'
                        : 'Emploi du temps compliqué? Optez pour un trajet planifié pour arriver à l\'heure.',
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
                label: hasActiveFilter
                    ? 'Réinitialiser les filtres'
                    : 'Planifiez un trajet',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final isSelected = _selectedReservations.contains(reservation.id);

    return GestureDetector(
      onTap: _isSelectionMode
          ? () => _toggleReservationSelection(reservation.id)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _isSelectionMode && isSelected
              ? AppColors.accent.withOpacity(0.1)
              : null,
          border: _isSelectionMode && isSelected
              ? Border.all(color: AppColors.accent, width: 2)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox en mode sélection
                  if (_isSelectionMode) ...[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.glassStroke,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                  ],

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
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
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
                        label: Text(AppLocalizations.of(context).call),
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
                        label: Text(AppLocalizations.of(context).message),
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
        ),
      ),
    );
  }

  Widget _buildCompletedTab() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return _buildNotLoggedInView();
    }

    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getUserCompletedReservationsStreamWithFilter(
        currentUser.uid,
        _completedFilter,
      ),
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

        // Mettre à jour les réservations actuelles pour l'export
        _currentReservations = reservations;

        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  _completedFilter.hasActiveFilter
                      ? 'Aucun résultat pour les filtres sélectionnés'
                      : 'Aucun trajet terminé',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[400],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _completedFilter.hasActiveFilter
                      ? 'Essayez de modifier vos critères de filtrage'
                      : 'Vos trajets terminés apparaîtront ici',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Indicateur du nombre de résultats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${reservations.length} résultat${reservations.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Liste des réservations
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];
                  return _buildCompletedReservationCard(reservation);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedReservationCard(Reservation reservation) {
    final isSelected = _selectedReservations.contains(reservation.id);

    return GestureDetector(
      onTap: _isSelectionMode
          ? () => _toggleReservationSelection(reservation.id)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _isSelectionMode && isSelected
              ? AppColors.accent.withOpacity(0.1)
              : null,
          border: _isSelectionMode && isSelected
              ? Border.all(color: AppColors.accent, width: 2)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox en mode sélection
                  if (_isSelectionMode) ...[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.glassStroke,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                  ],

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
                          '${reservation.totalPrice.toStringAsFixed(2)} CHF',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
        ),
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

  List<Widget> _buildNormalActions() {
    return [
      // Icône de sélection (à gauche)
      IconButton(
        onPressed: _toggleSelectionMode,
        icon: const Icon(Icons.checklist, color: AppColors.accent),
        tooltip: 'Sélectionner pour export',
      ),
      // Menu 3 points (à droite) identique à l'admin
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.accent),
        tooltip: 'Options de filtre et tri',
        onSelected: _handleMenuAction,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'filter',
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Filtrer'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'sort',
            child: Row(
              children: [
                Icon(Icons.sort, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Trier'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSelectionActions() {
    return [
      if (_selectedReservations.isNotEmpty)
        IconButton(
          onPressed: _exportSelectedReservations,
          icon: const Icon(Icons.picture_as_pdf, color: AppColors.accent),
          tooltip: 'Exporter sélection',
        ),
      IconButton(
        onPressed: _cancelSelection,
        icon: const Icon(Icons.close, color: AppColors.hot),
        tooltip: 'Annuler sélection',
      ),
    ];
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedReservations.clear();
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedReservations.clear();
    });
  }

  void _toggleReservationSelection(String reservationId) {
    setState(() {
      if (_selectedReservations.contains(reservationId)) {
        _selectedReservations.remove(reservationId);
      } else {
        _selectedReservations.add(reservationId);
      }
    });
  }

  // Actions du menu (identiques à admin)
  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        showReservationFilterBottomSheet(
          context: context,
          currentFilter: _tabController.index == 0
              ? _upcomingFilter
              : _completedFilter,
          isUpcoming: _tabController.index == 0,
          onFilterChanged: (filter) {
            setState(() {
              if (_tabController.index == 0) {
                _upcomingFilter = filter;
              } else {
                _completedFilter = filter;
              }
            });
          },
        );
        break;
      case 'sort':
        _showSortDialog();
        break;
    }
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserSortBottomSheet(
        currentSort: _tabController.index == 0
            ? _upcomingFilter.sortType
            : _completedFilter.sortType,
        isUpcoming: _tabController.index == 0,
        onSortChanged: (sortType) {
          setState(() {
            if (_tabController.index == 0) {
              _upcomingFilter = _upcomingFilter.copyWith(sortType: sortType);
            } else {
              _completedFilter = _completedFilter.copyWith(sortType: sortType);
            }
          });
        },
      ),
    );
  }

  // Bottom sheet de tri (copie de l'admin)
  // Note: déclarée plus bas en dehors du State.

  Future<void> _exportSelectedReservations() async {
    if (_selectedReservations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une course'),
          backgroundColor: AppColors.hot,
        ),
      );
      return;
    }

    final selectedReservations = _currentReservations
        .where((r) => _selectedReservations.contains(r.id))
        .toList();

    try {
      final pdfBytes = await PdfExportService.exportReservationsToPdf(
        reservations: selectedReservations,
        title: 'Mes Courses',
        subtitle: 'Export des courses sélectionnées',
        isAdmin: false,
      );

      await PdfExportService.sharePdf(pdfBytes, 'mes_courses');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF exporté avec succès !'),
          backgroundColor: AppColors.accent,
        ),
      );

      // Sortir du mode sélection après export
      _cancelSelection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: AppColors.hot,
        ),
      );
    }
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Compteur de sélection
            Expanded(
              child: Text(
                '${_selectedReservations.length} course${_selectedReservations.length > 1 ? 's' : ''} sélectionnée${_selectedReservations.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                ),
              ),
            ),

            // Bouton d'export
            if (_selectedReservations.isNotEmpty) ...[
              const SizedBox(width: 16),
              GlassButton(
                label: 'Exporter PDF',
                onPressed: _exportSelectedReservations,
                icon: Icons.picture_as_pdf,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Bottom sheet de tri (copie de l'admin) - déclarée en dehors du State
class _UserSortBottomSheet extends StatelessWidget {
  final ReservationSortType currentSort;
  final bool isUpcoming;
  final Function(ReservationSortType) onSortChanged;

  const _UserSortBottomSheet({
    required this.currentSort,
    required this.isUpcoming,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = isUpcoming
        ? [
            (
              ReservationSortType.dateAscending,
              'Départ le plus proche',
              Icons.schedule,
            ),
            (
              ReservationSortType.dateDescending,
              'Départ le plus lointain',
              Icons.schedule,
            ),
            (
              ReservationSortType.priceDescending,
              'Prix le plus élevé',
              Icons.trending_up,
            ),
            (
              ReservationSortType.priceAscending,
              'Prix le plus bas',
              Icons.trending_down,
            ),
          ]
        : [
            (
              ReservationSortType.dateDescending,
              'Fin la plus récente',
              Icons.history,
            ),
            (
              ReservationSortType.dateAscending,
              'Fin la plus ancienne',
              Icons.history,
            ),
            (
              ReservationSortType.priceDescending,
              'Prix le plus élevé',
              Icons.trending_up,
            ),
            (
              ReservationSortType.priceAscending,
              'Prix le plus bas',
              Icons.trending_down,
            ),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textWeak,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  isUpcoming ? Icons.schedule : Icons.history,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isUpcoming
                      ? 'Options de tri - Départ'
                      : 'Options de tri - Historique',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...sortOptions.map((option) {
            final (sortType, title, icon) = option;
            final isSelected = currentSort == sortType;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  onSortChanged(sortType);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.glassStroke,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textWeak,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? AppColors.accent : Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: AppColors.accent, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // plus d'implémentation ici, logique déplacée en helpers
}
