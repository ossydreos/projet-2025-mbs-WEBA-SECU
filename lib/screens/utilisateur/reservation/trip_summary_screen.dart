import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/vehicle_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/data/services/directions_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/promo_code.dart';
import 'package:my_mobility_services/data/services/promo_code_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/scheduling_screen.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/localisation_recherche_screen.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/booking_screen.dart';

class TripSummaryScreen extends StatefulWidget {
  final String vehicleName;
  final String departure;
  final String destination;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String estimatedArrival;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;
  final double calculatedPrice; // ✅ AJOUTER LE PRIX CALCULÉ

  const TripSummaryScreen({
    super.key,
    required this.vehicleName,
    required this.departure,
    required this.destination,
    required this.selectedDate,
    required this.selectedTime,
    required this.estimatedArrival,
    required this.calculatedPrice, // ✅ AJOUTER LE PRIX CALCULÉ
    this.departureCoordinates,
    this.destinationCoordinates,
  });

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  String _totalPrice = '0,00 CHF';
  final ReservationService _reservationService = ReservationService();
  bool _isCreatingReservation = false;
  double _calculatedPrice = 0.0;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  PromoCode? _appliedPromo;
  double _discountAmount = 0.0;
  bool _applyingPromo = false;
  final PromoCodeService _promoService = PromoCodeService();

  // Variables pour les données modifiables
  late String _currentDeparture;
  late String _currentDestination;
  late LatLng? _currentDepartureCoordinates;
  late LatLng? _currentDestinationCoordinates;
  late String _estimatedArrival;
  late String _currentVehicleName;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      final months = [
        AppLocalizations.of(context).jan,
        AppLocalizations.of(context).feb,
        AppLocalizations.of(context).mar,
        AppLocalizations.of(context).apr,
        AppLocalizations.of(context).may,
        AppLocalizations.of(context).jun,
        AppLocalizations.of(context).jul,
        AppLocalizations.of(context).aug,
        AppLocalizations.of(context).sep,
        AppLocalizations.of(context).oct,
        AppLocalizations.of(context).nov,
        AppLocalizations.of(context).dec,
      ];
      final month = months[date.month - 1];
      return '${AppLocalizations.of(context).today}, ${date.day} $month';
    } else {
      final weekdays = [
        AppLocalizations.of(context).monday,
        AppLocalizations.of(context).tuesday,
        AppLocalizations.of(context).wednesday,
        AppLocalizations.of(context).thursday,
        AppLocalizations.of(context).friday,
        AppLocalizations.of(context).saturday,
        AppLocalizations.of(context).sunday,
      ];
      final months = [
        AppLocalizations.of(context).jan,
        AppLocalizations.of(context).feb,
        AppLocalizations.of(context).mar,
        AppLocalizations.of(context).apr,
        AppLocalizations.of(context).may,
        AppLocalizations.of(context).jun,
        AppLocalizations.of(context).jul,
        AppLocalizations.of(context).aug,
        AppLocalizations.of(context).sep,
        AppLocalizations.of(context).oct,
        AppLocalizations.of(context).nov,
        AppLocalizations.of(context).dec,
      ];

      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];

      return '$weekday, ${date.day} $month';
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    // Initialiser les variables modifiables
    _currentDeparture = widget.departure;
    _currentDestination = widget.destination;
    _currentDepartureCoordinates = widget.departureCoordinates;
    _currentDestinationCoordinates = widget.destinationCoordinates;
    _estimatedArrival = widget.estimatedArrival;
    _currentVehicleName = widget.vehicleName;

    // ✅ UTILISER LE PRIX TRANSMIS AU LIEU DE LE RECALCULER
    _setCalculatedPrice();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // Mettre à jour avec une nouvelle route
  Future<void> _updateWithNewRoute(
    String departure,
    String destination,
    LatLng? departureCoords,
    LatLng? destinationCoords,
  ) async {
    setState(() {
      _currentDeparture = departure;
      _currentDestination = destination;
      _currentDepartureCoordinates = departureCoords;
      _currentDestinationCoordinates = destinationCoords;
    });

    // Calculer le prix et l'heure d'arrivée en parallèle
    _setCalculatedPrice();
    await _updateEstimatedArrival();
  }

  // Méthode pour gérer le retour de BookingScreen
  Future<void> _handleBookingScreenReturn(Map<String, dynamic>? result) async {
    if (result != null) {
      // Mettre à jour le nom du véhicule si fourni
      if (result.containsKey('vehicleName')) {
        setState(() {
          _currentVehicleName = result['vehicleName'];
        });
      }

      await _updateWithNewRoute(
        result['departure'],
        result['destination'],
        result['departureCoordinates'],
        result['destinationCoordinates'],
      );
    }
  }

  // Méthode pour mettre à jour l'heure d'arrivée estimée
  Future<void> _updateEstimatedArrival() async {
    if (_currentDepartureCoordinates != null &&
        _currentDestinationCoordinates != null) {
      try {
        // Calculer la durée du trajet avec les nouvelles coordonnées
        final directions = await DirectionsService.getDirections(
          origin: _currentDepartureCoordinates!,
          destination: _currentDestinationCoordinates!,
        );

        if (directions != null && directions.containsKey('durationValue')) {
          final durationSeconds = directions['durationValue'] as int;
          final durationMinutes = (durationSeconds / 60).round();

          // Calculer l'heure d'arrivée en ajoutant la durée à l'heure de départ
          final departureTime = DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            widget.selectedTime.hour,
            widget.selectedTime.minute,
          );

          final arrivalTime = departureTime.add(
            Duration(minutes: durationMinutes),
          );
          final arrivalTimeOfDay = TimeOfDay.fromDateTime(arrivalTime);

          setState(() {
            _estimatedArrival =
                '${arrivalTimeOfDay.hour.toString().padLeft(2, '0')}:${arrivalTimeOfDay.minute.toString().padLeft(2, '0')}';
          });
        }
      } catch (e) {
        print(AppLocalizations.of(context).errorCalculatingArrivalTime);
        // Garder l'heure d'arrivée par défaut
      }
    }
  }

  // Utiliser le prix transmis depuis booking_screen
  void _setCalculatedPrice() {
    print('🔥 DEBUG: Prix reçu = ${widget.calculatedPrice}');
    // ✅ Arrondir à 0.05 CHF près
    _calculatedPrice = (widget.calculatedPrice * 20).round() / 20;
    _totalPrice = '${_calculatedPrice.toStringAsFixed(2)} CHF';
    print(
      '🔥 DEBUG: Prix final arrondi = ${_calculatedPrice.toStringAsFixed(2)} CHF',
    );
    print('🔥 DEBUG: Prix affiché = $_totalPrice');
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    setState(() => _applyingPromo = true);
    try {
      final result = await _promoService.validatePromoCode(
        code,
        _calculatedPrice,
      );
      if (!result.isValid) {
        throw Exception(result.message);
      }

      setState(() {
        _appliedPromo = result.promoCode;
        _discountAmount = result.discountAmount;
        final total = (_calculatedPrice - _discountAmount).clamp(
          0,
          double.infinity,
        );
        _totalPrice = '${total.toStringAsFixed(2)} CHF';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).promoCodeApplied)));
    } catch (e) {
      setState(() {
        _appliedPromo = null;
        _discountAmount = 0.0;
        _totalPrice = '${_calculatedPrice.toStringAsFixed(2)} CHF';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).error(e.toString()))));
    } finally {
      if (mounted) setState(() => _applyingPromo = false);
    }
  }

  Future<void> _createReservation() async {
    if (_isCreatingReservation) return;

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      // ✅ LE PRIX EST DÉJÀ CALCULÉ DANS initState
      print('🔥 DEBUG RESERVATION: Prix utilisé = $_calculatedPrice');

      // Obtenir l'ID utilisateur (connecté ou temporaire)
      String userId;
      if (_reservationService.isUserLoggedIn()) {
        userId = _reservationService.getCurrentUserId()!;
      } else {
        // Utilisateur non connecté - créer un ID temporaire
        userId = 'temp_user_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Obtenir le nom d'utilisateur
      String? userName;
      if (_reservationService.isUserLoggedIn()) {
        final user = FirebaseAuth.instance.currentUser;
        userName =
            user?.displayName ?? user?.email?.split('@')[0] ?? AppLocalizations.of(context).user;
      } else {
        userName = AppLocalizations.of(context).guest;
      }

      // Créer la réservation
      final reservation = Reservation(
        id: '', // Sera généré par le service
        userId: userId,
        userName: userName,
        vehicleName: _currentVehicleName,
        departure: _currentDeparture,
        destination: _currentDestination,
        selectedDate: widget.selectedDate,
        selectedTime: _formatTime(widget.selectedTime),
        estimatedArrival: _estimatedArrival,
        paymentMethod: AppLocalizations.of(context).cash,
        totalPrice: _calculatedPrice,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        departureCoordinates: _currentDepartureCoordinates != null
            ? {
                'latitude': _currentDepartureCoordinates!.latitude,
                'longitude': _currentDepartureCoordinates!.longitude,
              }
            : null,
        destinationCoordinates: _currentDestinationCoordinates != null
            ? {
                'latitude': _currentDestinationCoordinates!.latitude,
                'longitude': _currentDestinationCoordinates!.longitude,
              }
            : null,
        clientNote: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        promoCode: _appliedPromo?.code,
        discountAmount: _discountAmount == 0.0 ? null : _discountAmount,
        isPaid: true, // La réservation est payée à la création
        isCompleted: false, // Pas encore terminée
      );

      // Sauvegarder dans Firebase
      print(
        AppLocalizations.of(context).reservationSavedWithVehicle(_currentVehicleName),
      );
      if (_appliedPromo != null) {
        try {
          await _promoService.applyPromoCode(_appliedPromo!.id);
        } catch (e) {
          // ignorer l'erreur de redeem pour ne pas bloquer la réservation
        }
      }

      final reservationId = await _reservationService.createReservation(
        reservation,
      );
      print(AppLocalizations.of(context).reservationCreatedWithId(reservationId));

      // Afficher le succès (ajoute le code promo s'il est utilisé)
      if (mounted) {
        final baseMsg = AppLocalizations.of(
          context,
        ).reservationCreatedSuccess(reservationId);
        final promoMsg = _appliedPromo != null
            ? '\n${AppLocalizations.of(context).promoCodeUsed(_appliedPromo!.code)}'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$baseMsg$promoMsg'),
            backgroundColor: AppColors.accent,
          ),
        );

        // Aller directement à l'accueil
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).reservationCreationError(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReservation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header avec X
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showExitConfirmation(),
                      child: const Icon(
                        Icons.close,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Titre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).reviewPlannedTrip,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Contenu scrollable pour éviter les overflows
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Section Date et heure
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context).dateAndTime,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    // Aller à la page de planification
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SchedulingScreen(
                                          vehicleName: _currentVehicleName,
                                          departure: _currentDeparture,
                                          destination: _currentDestination,
                                          departureCoordinates:
                                              _currentDepartureCoordinates,
                                          destinationCoordinates:
                                              _currentDestinationCoordinates,
                                          calculatedPrice:
                                              _calculatedPrice, // ✅ AJOUTER LE PRIX
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).modify,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_formatDate(widget.selectedDate)} à ${_formatTime(widget.selectedTime)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: AppColors.textWeak.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                      const SizedBox(height: 24),

                      // Section Itinéraire
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context).route,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    // Aller à la page de recherche de localisation
                                    // qui redirigera vers BookingScreen
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LocationSearchScreen(
                                              initialDeparture:
                                                  widget.departure,
                                              initialDestination:
                                                  widget.destination,
                                              departureCoordinates:
                                                  widget.departureCoordinates,
                                              destinationCoordinates:
                                                  widget.destinationCoordinates,
                                              fromSummary: true,
                                            ),
                                      ),
                                    );

                                    // Si on revient de BookingScreen avec des données mises à jour
                                    if (result != null) {
                                      await _handleBookingScreenReturn(result);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).modify,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Visualisation de l'itinéraire
                            Row(
                              children: [
                                // Point de départ (flexible)
                                Flexible(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(context).pickupAddress,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textWeak,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentDeparture,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Ligne de connexion
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 2,
                                        color: AppColors.textWeak.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Point d'arrivée (flexible)
                                Flexible(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.text,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(context).destinationAddress,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textWeak,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentDestination,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ETA
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
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
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${AppLocalizations.of(context).estimatedArrival}: $_estimatedArrival',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: AppColors.textWeak.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                      const SizedBox(height: 24),

                      // Section Véhicule
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context).vehicle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    // Aller à la page de sélection des véhicules
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingScreen(
                                          departure: _currentDeparture,
                                          destination: _currentDestination,
                                          departureCoordinates:
                                              _currentDepartureCoordinates,
                                          destinationCoordinates:
                                              _currentDestinationCoordinates,
                                          fromSummary: true,
                                        ),
                                      ),
                                    );

                                    // Si l'utilisateur a changé de véhicule, mettre à jour
                                    if (result != null) {
                                      await _handleBookingScreenReturn(result);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.accent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context).modify,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: AppColors.accent,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentVehicleName,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textWeak,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: AppColors.textWeak.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                      const SizedBox(height: 24),

                      // Section Code promo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).promoCode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entrez un code promo pour bénéficier d\'une réduction',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textWeak,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.textWeak.withOpacity(
                                          0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _promoController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context).enterPromoCode,
                                        hintStyle: TextStyle(
                                          color: AppColors.textWeak,
                                          fontSize: 16,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _applyingPromo
                                      ? null
                                      : _applyPromo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _applyingPromo
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(AppLocalizations.of(context).apply),
                                ),
                              ],
                            ),
                            // Affichage du code promo appliqué
                            if (_appliedPromo != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppLocalizations.of(context).promoCode} appliqué: ${_appliedPromo!.code}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            'Remise: -${_discountAmount.toStringAsFixed(2)} CHF',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _appliedPromo = null;
                                          _discountAmount = 0.0;
                                          _totalPrice =
                                              '${_calculatedPrice.toStringAsFixed(2)} CHF';
                                          _promoController.clear();
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: AppColors.textWeak.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                      const SizedBox(height: 24),

                      // Section Note pour le chauffeur
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Note pour le chauffeur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ajoutez des informations utiles pour votre chauffeur (optionnel)',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textWeak,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _noteController,
                              maxLines: 3,
                              maxLength: 200,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Ajoutez une note pour votre chauffeur...',
                                hintStyle: TextStyle(
                                  color: AppColors.textWeak,
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.textWeak.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.textWeak.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.accent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                contentPadding: const EdgeInsets.all(16),
                                counterStyle: TextStyle(
                                  color: AppColors.textWeak,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // fin contenu scrollable
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Section Prix et Bouton Confirmer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Affichage du prix
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.textWeak.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context).price,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textWeak,
                                ),
                              ),
                              Text(
                                '${_calculatedPrice.toStringAsFixed(2)} CHF',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_appliedPromo != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remise (${_appliedPromo!.code})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '-${_discountAmount.toStringAsFixed(2)} CHF',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: AppColors.textWeak.withOpacity(0.3),
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context).total,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _totalPrice,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Divider(
                              color: AppColors.textWeak.withOpacity(0.3),
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context).total,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _totalPrice,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreatingReservation
                            ? null
                            : _createReservation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isCreatingReservation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context).createReservation,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.bgElev,
          title: const Text(
            'Annuler la réservation',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir annuler cette réservation ? Toutes les informations saisies seront perdues.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).no, style: TextStyle(color: AppColors.text)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer la boîte de dialogue
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: Text(
                'Oui, annuler',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        );
      },
    );
  }
}
