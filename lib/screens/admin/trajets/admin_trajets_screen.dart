import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/models/reservation_filter.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/pdf_export_service.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/widgets/admin/reservation_filter_widget.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/screens/ride_chat/ride_chat_screen.dart';
import 'package:my_mobility_services/widgets/widget_navTrajets.dart';

class AdminTrajetsScreen extends StatefulWidget {
  const AdminTrajetsScreen({super.key});

  @override
  State<AdminTrajetsScreen> createState() => _AdminTrajetsScreenState();
}

class _AdminTrajetsScreenState extends State<AdminTrajetsScreen>
    with TickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  final CustomOfferService _customOfferService = CustomOfferService();

  int _selectedIndex = 1;
  late TabController _tabController;

  // Variables pour le filtrage avancé - séparés pour chaque onglet
  ReservationFilter _upcomingFilter = const ReservationFilter(
    isUpcoming: true,
    filterType: ReservationFilterType.all,
    sortType: ReservationSortType.dateDescending,
  );
  ReservationFilter _completedFilter = const ReservationFilter(
    isUpcoming: false,
    filterType: ReservationFilterType.all,
    sortType: ReservationSortType.dateDescending,
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
          appBar: GlassAppBar(
            title: AppLocalizations.of(context).courses,
            actions: _isSelectionMode
                ? _buildSelectionActions()
                : _buildNormalActions(),
          ),
          body: Column(
            children: [
              // Barre de navigation des onglets séparée
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TrajetNav(
                  _tabController,
                  onTabChanged: _handleTabChange,
                ),
              ),
              // Contenu des onglets
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildUpcomingTab(), _buildCompletedTab()],
                ),
              ),
              _isSelectionMode
                  ? _buildSelectionBottomBar()
                  : AdminBottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: _handleNavigation,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour récupérer une offre personnalisée par son ID
  Future<CustomOffer?> _getCustomOfferById(String offerId) async {
    try {
      return await _customOfferService.getCustomOfferById(offerId);
    } catch (e) {
      print('Erreur lors de la récupération de l\'offre personnalisée: $e');
      return null;
    }
  }

  Widget _buildUpcomingTab() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getUpcomingReservationsStreamWithFilter(
        _upcomingFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.hot),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).loadingError,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final reservations = snapshot.data ?? [];

        // Mettre à jour les réservations actuelles pour l'export
        _currentReservations = reservations;

        if (reservations.isEmpty) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: AppColors.accent.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _upcomingFilter.hasActiveFilter
                        ? 'Aucun résultat pour les filtres sélectionnés'
                        : AppLocalizations.of(context).noUpcomingRides,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _upcomingFilter.hasActiveFilter
                        ? 'Essayez de modifier vos critères de filtrage'
                        : AppLocalizations.of(context).upcomingRidesWillAppear,
                    style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(reservations[index], isUpcoming: true);
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getCompletedReservationsStreamWithFilter(
        _completedFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.hot),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).loadingError,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        List<Reservation> reservations = snapshot.data ?? [];

        // Mettre à jour les réservations actuelles pour l'export
        _currentReservations = reservations;

        if (reservations.isEmpty) {
          return Center(
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.accent.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _completedFilter.hasActiveFilter
                        ? 'Aucun résultat pour les filtres sélectionnés'
                        : AppLocalizations.of(context).noCompletedRides,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _completedFilter.hasActiveFilter
                        ? 'Essayez de modifier vos critères de filtrage'
                        : AppLocalizations.of(context).rideHistoryWillAppear,
                    style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(
              reservations[index],
              isUpcoming: false,
              showDeleteButton: false,
            );
          },
        );
      },
    );
  }

  Widget _buildReservationCard(
    Reservation reservation, {
    required bool isUpcoming,
    bool showDeleteButton = false,
  }) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête compact avec statut et ID de course
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
                    // Icône 3 points à droite de l'icône de sélection
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleReservationMenuAction(value, reservation),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Détails'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Supprimer'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.textWeak.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textWeak.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: AppColors.textWeak,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course #${reservation.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWeak,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reservation.userName ?? 'Client',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textStrong,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Badge "Demande personnalisée" si applicable
                      if (reservation.type == ReservationType.offer) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Demande personnalisée',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Pour les trajets à venir: afficher uniquement la bulle Chat (remplace statut + i)
                      if (isUpcoming) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideChatScreen(
                                  reservationId: reservation.id,
                                  isAdmin: true,
                                  userIdForAdmin: reservation.userId,
                                  clientName: reservation.userName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble, size: 18),
                          label: Text(AppLocalizations.of(context).chat),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.accent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Pour les terminées: conserver le statut et ajouter la bulle Chat à droite, sans l'icône i
                        if (reservation.type == ReservationType.reservation) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                reservation.status,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(reservation.status),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(reservation.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(reservation.status),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideChatScreen(
                                  reservationId: reservation.id,
                                  isAdmin: true,
                                  userIdForAdmin: reservation.userId,
                                  clientName: reservation.userName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble, size: 18),
                          label: Text(AppLocalizations.of(context).chat),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.accent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations compactes du trajet
              _buildCompactLocationRow(
                icon: Icons.location_on,
                iconColor: Colors.green,
                address: reservation.departure,
              ),
              const SizedBox(height: 6),
              _buildCompactLocationRow(
                icon: Icons.flag,
                iconColor: AppColors.hot,
                address: reservation.destination,
              ),
              const SizedBox(height: 6),

              // Moyen de paiement et prix sous les adresses
              Row(
                children: [
                  const Icon(Icons.credit_card, color: AppColors.textWeak, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    reservation.paymentMethod.isNotEmpty
                        ? reservation.paymentMethod
                        : 'Paiement',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textWeak,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  // Prix
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Affichage des dates selon le type de réservation
              if (reservation.type == ReservationType.offer) ...[
                // Pour les offres personnalisées, utiliser un FutureBuilder pour récupérer les dates
                FutureBuilder<CustomOffer?>(
                  future: _getCustomOfferById(reservation.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final offer = snapshot.data!;
                      return Column(
                        children: [
                          // Date de début
                          if (offer.startDateTime != null) ...[
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: AppColors.textWeak),
                                const SizedBox(width: 6),
                                Text(
                                  'Début: ${offer.startDateTime!.day}/${offer.startDateTime!.month}/${offer.startDateTime!.year} à ${offer.startDateTime!.hour.toString().padLeft(2, '0')}:${offer.startDateTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textWeak,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          // Date de fin
                          if (offer.endDateTime != null) ...[
                            Row(
                              children: [
                                Icon(Icons.flag, size: 14, color: AppColors.textWeak),
                                const SizedBox(width: 6),
                                Text(
                                  'Fin: ${offer.endDateTime!.day}/${offer.endDateTime!.month}/${offer.endDateTime!.year} à ${offer.endDateTime!.hour.toString().padLeft(2, '0')}:${offer.endDateTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textWeak,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          
                          // Prix proposé pour les offres personnalisées
                          if (offer.proposedPrice != null) ...[
                            Row(
                              children: [
                                Icon(Icons.attach_money, size: 14, color: AppColors.accent),
                                const SizedBox(width: 6),
                                Text(
                                  'Prix: ${offer.proposedPrice!.toStringAsFixed(2)} CHF',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    } else {
                      // Fallback si on ne peut pas récupérer l'offre
                      return Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: AppColors.textWeak),
                          const SizedBox(width: 6),
                          Text(
                            _formatCompactDateTime(
                              reservation.selectedDate,
                              reservation.selectedTime,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textWeak,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ] else ...[
                // Pour les réservations normales, affichage simple
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppColors.textWeak),
                    const SizedBox(width: 6),
                    Text(
                      _formatCompactDateTime(
                        reservation.selectedDate,
                        reservation.selectedTime,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textWeak,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Boutons d'action
              Row(
                children: [
                  // Boutons d'action pour les courses à venir
                  if (isUpcoming) ...[
                    Expanded(
                      child: _buildActionButton(
                        label: 'Terminer',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onPressed: () => _completeReservation(reservation),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Annuler',
                        icon: Icons.cancel,
                        color: AppColors.hot,
                        onPressed: () => _showCancelDialog(reservation),
                      ),
                    ),
                  ],
                  // Bouton de suppression pour les courses terminées
                  if (showDeleteButton) ...[
                    Expanded(
                      child: _buildActionButton(
                        label: 'Supprimer',
                        icon: Icons.delete_outline,
                        color: AppColors.hot,
                        onPressed: () => _showDeleteConfirmation(reservation),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ligne de localisation compacte
  Widget _buildCompactLocationRow({
    required IconData icon,
    required Color iconColor,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Bouton d'action avec label
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formatage compact des dates
  String _formatCompactDateTime(DateTime date, String time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    String dateText;
    if (selectedDay == today) {
      dateText = 'Aujourd\'hui';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      dateText = 'Demain';
    } else {
      dateText =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }

    return '$dateText à $time';
  }

  // Dialog des détails complets
  void _showDetailsDialog(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Détails de la course #${reservation.id.substring(0, 8)}',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type de réservation (demande personnalisée ou normale)
                if (reservation.type == ReservationType.offer) ...[
                  _buildCompactDetailSection(
                    'Type',
                    Icons.star,
                    'Demande personnalisée',
                  ),
                  const SizedBox(height: 12),
                ],

                // Informations du client
                _buildCompactDetailSection(
                  'Client',
                  Icons.person,
                  reservation.userName ?? 'Client',
                ),
                const SizedBox(height: 12),

                // Trajet
                _buildCompactDetailSection(
                  'Départ',
                  Icons.location_on,
                  reservation.departure,
                ),
                const SizedBox(height: 8),
                _buildCompactDetailSection(
                  'Destination',
                  Icons.flag,
                  reservation.destination,
                ),
                const SizedBox(height: 12),

                // Date et heure
                _buildCompactDetailSection(
                  'Date et heure',
                  Icons.schedule,
                  _formatDateTimeWithTimezone(
                    reservation.selectedDate,
                    reservation.selectedTime,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCompactDetailSection(
                  'Arrivée estimée',
                  Icons.access_time,
                  reservation.estimatedArrival,
                ),
                const SizedBox(height: 12),

                // Paiement
                _buildCompactPaymentDetails(reservation),

                // Code promo si applicable
                if (reservation.promoCode != null &&
                    reservation.promoCode!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCompactDetailSection(
                    'Code promo',
                    Icons.local_offer,
                    '${reservation.promoCode!} ${reservation.discountAmount != null && reservation.discountAmount! > 0 ? '(-${_formatSwissCurrency(reservation.discountAmount!)})' : ''}',
                  ),
                ],

                // Note du client si elle existe
                if (reservation.clientNote != null &&
                    reservation.clientNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCompactDetailSection(
                    'Note du client',
                    Icons.note_alt,
                    reservation.clientNote!,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Fermer',
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Section de détail compacte dans le dialog
  Widget _buildCompactDetailSection(String label, IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWeak,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Détails de paiement compacts dans le dialog
  Widget _buildCompactPaymentDetails(Reservation reservation) {
    final basePrice =
        reservation.totalPrice + (reservation.discountAmount ?? 0.0);
    final discount = reservation.discountAmount ?? 0.0;
    final total = reservation.totalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre paiement
        Row(
          children: [
            Icon(Icons.payment, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Paiement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Moyen de paiement
        _buildCompactPaymentRow(
          'Moyen de paiement',
          Icons.credit_card,
          reservation.paymentMethod,
        ),
        const SizedBox(height: 6),

        // Sous-total
        _buildCompactPaymentRow(
          'Sous-total',
          Icons.money,
          _formatSwissCurrency(basePrice),
        ),

        // Remise si applicable
        if (discount > 0) ...[
          const SizedBox(height: 6),
          _buildCompactPaymentRow(
            'Remise',
            Icons.discount,
            '-${_formatSwissCurrency(discount)}',
            isDiscount: true,
          ),
        ],

        const SizedBox(height: 8),

        // Séparateur
        Container(height: 1, color: AppColors.textWeak.withOpacity(0.3)),

        const SizedBox(height: 8),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            Text(
              _formatSwissCurrency(total),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Ligne de paiement compacte dans le dialog
  Widget _buildCompactPaymentRow(
    String label,
    IconData icon,
    String value, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isDiscount ? Colors.green : AppColors.textWeak,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textWeak,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: isDiscount ? Colors.green : AppColors.textStrong,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      // Les statuts counterOffered et waitingPayment n'existent plus
      case ReservationStatus.inProgress:
        return AppColors.accent;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return AppColors.hot;
    }
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      // Les statuts counterOffered et waitingPayment n'existent plus
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
    }
  }

  Future<void> _completeReservation(Reservation reservation) async {
    try {
      // Marquer la course comme terminée avec notification
      await _reservationService.completeReservation(reservation.id);
      if (mounted) {
        _showSuccessMessage('Course marquée comme terminée !');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erreur: $e');
      }
    }
  }

  Future<void> _showCancelDialog(Reservation reservation) async {
    await showGlassConfirmDialog(
      context: context,
      title: AppLocalizations.of(context).cancelRide,
      message: AppLocalizations.of(context).cancelRideConfirmation,
      confirmText: AppLocalizations.of(context).yesCancel,
      cancelText: AppLocalizations.of(context).no,
      icon: Icons.warning,
      iconColor: AppColors.hot,
      onConfirm: () {
        Navigator.of(context).pop();
        _cancelConfirmedReservation(reservation);
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _cancelConfirmedReservation(Reservation reservation) async {
    print('🚫 Annulation de la course: ${reservation.id}');
    print('🚫 Statut actuel: ${reservation.status}');

    try {
      // Marquer la course comme annulée (disparaît de la liste des courses à venir)
      await _reservationService.updateReservationStatus(
        reservation.id,
        ReservationStatus.cancelled,
      );
      print('✅ Course marquée comme annulée avec succès');

      if (mounted) {
        _showSuccessMessage('Course annulée et retirée de la liste !');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'annulation: $e');
      if (mounted) {
        _showErrorMessage('Erreur: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.hot,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Formatage des dates avec fuseau horaire pour l'admin
  String _formatDateTimeWithTimezone(DateTime date, String time) {
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return 'Départ prévu: $formattedDate, $time (CEST)';
  }

  // Formatage des devises suisses
  String _formatSwissCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Ajouter des apostrophes pour les milliers
    String formattedInteger = integerPart;
    if (integerPart.length > 3) {
      final reversed = integerPart.split('').reversed.join('');
      final withApostrophes = reversed.replaceAllMapped(
        RegExp(r'(\d{3})(?=\d)'),
        (match) => '${match.group(1)}\'',
      );
      formattedInteger = withApostrophes.split('').reversed.join('');
    }

    return 'CHF $formattedInteger.$decimalPart';
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

  // Méthodes pour la suppression

  void _showDeleteConfirmation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.hot, size: 24),
              const SizedBox(width: 12),
              Text(
                'Supprimer la course',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir supprimer cette course ?',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course #${reservation.id.substring(0, 8)}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.userName} • ${reservation.departure} → ${reservation.destination}',
                      style: TextStyle(
                        color: AppColors.textWeak,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette action est irréversible.',
                style: TextStyle(
                  color: AppColors.hot,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReservation(reservation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hot,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReservation(Reservation reservation) async {
    print('🗑️ Tentative de suppression de la réservation: ${reservation.id}');

    try {
      await _reservationService.deleteReservation(reservation.id);
      print('✅ Réservation supprimée avec succès');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Course #${reservation.id.substring(0, 8)} supprimée',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Widget> _buildNormalActions() {
    List<Widget> actions = [];

    // Le bouton de sélection n'est disponible que pour les courses terminées
    if (_tabController.index == 1) {
      actions.add(
        IconButton(
          onPressed: _toggleSelectionMode,
          icon: const Icon(Icons.checklist, color: AppColors.accent),
          tooltip: 'Sélectionner pour export',
        ),
      );
    }

    // Menu avec 3 points pour filtrer et trier (placé après pour être à droite)
    actions.add(
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.accent),
        tooltip: 'Options de filtre et tri',
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'filter',
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Filtrer'),
              ],
            ),
          ),
          const PopupMenuItem(
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
    );

    return actions;
  }

  List<Widget> _buildSelectionActions() {
    return [
      IconButton(
        onPressed: _cancelSelection,
        icon: const Icon(Icons.close, color: AppColors.hot),
        tooltip: 'Annuler sélection',
      ),
    ];
  }

  void _handleTabChange(int index) {
    setState(() {
      // Désactiver le mode sélection quand on change d'onglet
      _isSelectionMode = false;
      _selectedReservations.clear();
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        // Ouvrir directement la feuille de filtres via le helper public
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

  void _handleReservationMenuAction(String action, Reservation reservation) {
    switch (action) {
      case 'details':
        _showDetailsDialog(reservation);
        break;
      case 'delete':
        _showDeleteConfirmation(reservation);
        break;
    }
  }

  // _showFilterDialog supprimé: on utilise le helper showReservationFilterBottomSheet

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SortBottomSheet(
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
        title: 'Export des Courses',
        subtitle: 'Export des courses sélectionnées',
        isAdmin: true,
      );

      await PdfExportService.sharePdf(pdfBytes, 'export_courses');

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

  void _showBulkDeleteConfirmation() {
    final selectedReservations = _currentReservations
        .where((r) => _selectedReservations.contains(r.id))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.hot, size: 24),
              const SizedBox(width: 12),
              Text(
                'Supprimer les courses',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir supprimer ${selectedReservations.length} course${selectedReservations.length > 1 ? 's' : ''} ?',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Courses sélectionnées:',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedReservations
                        .take(3)
                        .map(
                          (reservation) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${reservation.userName} • ${reservation.departure} → ${reservation.destination}',
                              style: TextStyle(
                                color: AppColors.textWeak,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                    if (selectedReservations.length > 3)
                      Text(
                        '... et ${selectedReservations.length - 3} autre${selectedReservations.length - 3 > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppColors.textWeak,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette action est irréversible.',
                style: TextStyle(
                  color: AppColors.hot,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedReservations();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hot,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedReservations() async {
    final selectedReservations = _currentReservations
        .where((r) => _selectedReservations.contains(r.id))
        .toList();

    print('🗑️ Suppression en lot de ${selectedReservations.length} courses');

    try {
      // Supprimer toutes les courses sélectionnées
      for (final reservation in selectedReservations) {
        await _reservationService.deleteReservation(reservation.id);
        print('✅ Course ${reservation.id} supprimée');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${selectedReservations.length} course${selectedReservations.length > 1 ? 's' : ''} supprimée${selectedReservations.length > 1 ? 's' : ''}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Sortir du mode sélection après suppression
        _cancelSelection();
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression en lot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        children: [
          // Icône de partage (export PDF) à gauche
          Expanded(
            child: GestureDetector(
              onTap: _exportSelectedReservations,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.share,
                  color: AppColors.textStrong,
                  size: 24,
                ),
              ),
            ),
          ),

          // Texte centré avec le nombre de sélections
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${_selectedReservations.length} sélectionnée${_selectedReservations.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          // Icône de corbeille (suppression) à droite
          Expanded(
            child: GestureDetector(
              onTap: _showBulkDeleteConfirmation,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textStrong,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortBottomSheet extends StatelessWidget {
  final ReservationSortType currentSort;
  final bool isUpcoming;
  final Function(ReservationSortType) onSortChanged;

  const _SortBottomSheet({
    required this.currentSort,
    required this.isUpcoming,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = isUpcoming
        ? [
            // Options de tri pour les courses à venir
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
            // Options de tri pour les courses terminées
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textWeak,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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

          // Options
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

}
