import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/localisation_recherche_screen.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/booking_screen.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/theme/google_map_styles.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/widgets/utilisateur/paneau_recherche.dart';
import 'package:my_mobility_services/widgets/utilisateur/reservation/pending_reservation_sheet.dart';
import 'package:my_mobility_services/widgets/utilisateur/reservation/confirmed_reservation_sheet.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/admin_service.dart';
import 'package:my_mobility_services/data/services/notification_service.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/reservation_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/generated/app_localizations.dart';

class AccueilScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const AccueilScreen({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen>
    with AutomaticKeepAliveClientMixin {
  gmaps.GoogleMapController? _googleMapController;
  final ReservationService _reservationService = ReservationService();
  final AdminService _adminService = AdminService();
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 0;

  String? _selectedDestination;
  LatLng? _destinationCoordinates;
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  String _locationError = '';

  final Set<gmaps.Marker> _gmMarkers = <gmaps.Marker>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
      _listenToNotifications();
    });
  }

  // Écouter les notifications en temps réel
  void _listenToNotifications() {
    // Désactivé - pas de notification automatique
    // L'utilisateur verra directement le changement dans l'interface
  }


  @override
  bool get wantKeepAlive => true;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    widget.onNavigate?.call(index);
  }

  Future<void> _getUserLocation() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = true;
        _locationError = '';
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError = AppLocalizations.of(context).locationServicesDisabled;
          _isLoadingLocation = false;
        });
        _addDefaultLocationMarker();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          // Sur iOS, requestPermission() peut lever une exception
          print('Erreur lors de la demande de permission: $e');
          if (!mounted) return;
          setState(() {
            _locationError = AppLocalizations.of(context).locationPermissionNotAvailable;
            _isLoadingLocation = false;
          });
          _addDefaultLocationMarker();
          return;
        }
        
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationError = AppLocalizations.of(context).locationPermissionDenied;
            _isLoadingLocation = false;
          });
          _addDefaultLocationMarker();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError = AppLocalizations.of(context).locationPermissionDeniedPermanently;
          _isLoadingLocation = false;
        });
        _addDefaultLocationMarker();
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Sur iOS, getCurrentPosition peut échouer même avec les permissions
        print('Erreur lors de l\'obtention de la position: $e');
        if (!mounted) return;
        setState(() {
          _locationError = AppLocalizations.of(context).unableToGetCurrentPosition;
          _isLoadingLocation = false;
        });
        _addDefaultLocationMarker();
        return;
      }

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position!.latitude, position!.longitude);
        _isLoadingLocation = false;
      });

      _addUserLocationMarker();

      _googleMapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(_userLocation!.latitude, _userLocation!.longitude),
          15.0,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Erreur lors de la localisation: ${e.toString()}';
        _isLoadingLocation = false;
      });
      _addDefaultLocationMarker();
    }
  }

  void _addUserLocationMarker() {
    final userLocation = _userLocation ?? LatLng(46.183355, 6.09998); // 106 Bois de la Chapelle, Onex, Suisse
    final marker = gmaps.Marker(
      markerId: const gmaps.MarkerId('user'),
      position: gmaps.LatLng(userLocation.latitude, userLocation.longitude),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueAzure,
      ),
    );
    setState(() {
      _gmMarkers.removeWhere((m) => m.markerId == const gmaps.MarkerId('user'));
      _gmMarkers.add(marker);
    });
  }

  void _addDefaultLocationMarker() {
    setState(() {
      _userLocation = LatLng(46.183355, 6.09998); // 106 Bois de la Chapelle, Onex, Suisse
    });
    _addUserLocationMarker();
  }

  void _addDestinationMarker(LatLng destination) {
    final marker = gmaps.Marker(
      markerId: const gmaps.MarkerId('destination'),
      position: gmaps.LatLng(destination.latitude, destination.longitude),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueRed,
      ),
    );
    setState(() {
      _gmMarkers.removeWhere(
        (m) => m.markerId == const gmaps.MarkerId('destination'),
      );
      _gmMarkers.add(marker);
    });
    _fitMapToShowBothMarkers(destination);
  }

  void _fitMapToShowBothMarkers(LatLng destination) {
    final user = _userLocation ?? LatLng(46.183355, 6.09998); // 106 Bois de la Chapelle, Onex, Suisse
    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        user.latitude < destination.latitude
            ? user.latitude
            : destination.latitude,
        user.longitude < destination.longitude
            ? user.longitude
            : destination.longitude,
      ),
      northeast: gmaps.LatLng(
        user.latitude > destination.latitude
            ? user.latitude
            : destination.latitude,
        user.longitude > destination.longitude
            ? user.longitude
            : destination.longitude,
      ),
    );
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _googleMapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(_userLocation!.latitude, _userLocation!.longitude),
          15.0,
        ),
      );
    } else {
      _getUserLocation();
    }
  }

  void _openLocationSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LocationSearchScreen(currentDestination: _selectedDestination),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null) {
      if (result['departure'] != null && result['destination'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingScreen(
              departure: result['departure'],
              destination: result['destination'],
              departureCoordinates: result['departureCoordinates'],
              destinationCoordinates: result['destinationCoordinates'],
            ),
          ),
        );
      } else {
        setState(() {
          _selectedDestination = result['address'];
          _destinationCoordinates = result['coordinates'];
        });
        if (_destinationCoordinates != null) {
          _addDestinationMarker(_destinationCoordinates!);
        }
      }
    }
  }


  Widget _buildPendingReservationPanel(Reservation reservation) {
    final isWaitingPayment = reservation.status == ReservationStatus.confirmed;
    
    if (isWaitingPayment) {
      // Sheet pour réservation confirmée (paiement)
      return ConfirmedReservationSheet(
        reservation: reservation,
        onCancel: () => _cancelReservation(reservation),
        onCall: _makePhoneCall,
        onMessage: _sendSMS,
        onPay: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationDetailScreen(
                reservation: reservation,
              ),
            ),
          );
        },
      );
    } else {
      // Sheet pour réservation en attente
      return PendingReservationSheet(
        reservation: reservation,
        onCancel: () => _cancelReservation(reservation),
        onCall: _makePhoneCall,
        onMessage: _sendSMS,
      );
    }
  }

  // Ancienne méthode (gardée pour référence) - COMMENTÉE
  /*
  Widget _buildPendingReservationPanelOld(Reservation reservation) {
    final isWaitingPayment = reservation.status == ReservationStatus.confirmed;
    
    return GlassContainer(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isWaitingPayment 
                      ? AppColors.accent.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isWaitingPayment ? Icons.payment : Icons.schedule,
                  color: isWaitingPayment ? AppColors.accent : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWaitingPayment 
                          ? (reservation.hasCounterOffer 
                              ? 'CONTRE-OFFRE DU CHAUFFEUR !'
                              : 'Réservation confirmée !')
                          : AppLocalizations.of(context).reservationPending,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isWaitingPayment 
                          ? (reservation.hasCounterOffer 
                              ? 'Le chauffeur a proposé une contre-offre. Validez et payez'
                              : AppLocalizations.of(context).validateAndPayReservation)
                          : AppLocalizations.of(context).waitingDriverConfirmation,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isWaitingPayment 
                      ? AppColors.accent.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isWaitingPayment 
                      ? (reservation.hasCounterOffer ? AppLocalizations.of(context).counterOffer : AppLocalizations.of(context).toPay)
                      : AppLocalizations.of(context).waitingConfirmation,
                  style: TextStyle(
                    fontSize: 12,
                    color: isWaitingPayment 
                        ? (reservation.hasCounterOffer ? Colors.orange : AppColors.accent)
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.vehicleName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    // Affichage spécial pour les contre-offres
                    if (isWaitingPayment && reservation.hasCounterOffer && reservation.driverProposedDate != null && reservation.driverProposedTime != null) ...[
                      // Vérifier si la date a changé
                      Builder(
                        builder: (context) {
                          // Vérifier si la date a changé (comparer seulement jour/mois/année)
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
                          
                          // Vérifier si l'heure a changé
                          final timeChanged = reservation.selectedTime != reservation.driverProposedTime;
                          
                          if (dateChanged || timeChanged) {
                            return Row(
                              children: [
                                // Ancienne heure barrée
                                Text(
                                  '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Flèche
                                const Icon(Icons.arrow_forward, color: AppColors.accent, size: 16),
                                const SizedBox(width: 8),
                                // Nouvelle heure en gras
                                Text(
                                  '${reservation.driverProposedDate!.day}/${reservation.driverProposedDate!.month} à ${reservation.driverProposedTime}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Aucun changement, affichage normal
                            return Text(
                              '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      // Affichage normal
                      Text(
                        '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
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
                                'Votre note:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reservation.clientNote!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
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
          ),
          // Message d'information seulement pour les réservations en attente
          if (reservation.status == ReservationStatus.pending) ...[
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre réservation est en cours de traitement. Vous ne pouvez pas faire une nouvelle réservation tant qu\'elle n\'est pas confirmée.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Boutons d'action en dehors du container principal
          if (reservation.status == ReservationStatus.confirmed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showReservationDetail(reservation),
                    icon: const Icon(Icons.payment, size: 20),
                    label: Text(AppLocalizations.of(context).viewDetailsAndPay),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Petit bouton carré rouge avec X
                GestureDetector(
                  onTap: () => _cancelReservation(reservation),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (reservation.status == ReservationStatus.pending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelReservation(reservation),
                icon: const Icon(Icons.cancel, size: 20),
                label: Text(AppLocalizations.of(context).cancelReservationButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          // Boutons de contact pour les réservations en attente
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
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // IMPORTANT : permet au body de passer SOUS la navbar (elle reste au-dessus et à la bonne place)
        extendBody: true,
        body: Stack(
          children: [
            // --- MAP ---
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(
                  (_userLocation ?? const LatLng(46.183355, 6.09998)).latitude, // 106 Bois de la Chapelle, Onex, Suisse
                  (_userLocation ?? const LatLng(46.183355, 6.09998)).longitude,
                ),
                zoom: _userLocation != null ? 15.0 : 14.0,
              ),
              onMapCreated: (controller) {
                _googleMapController = controller;
                controller.setMapStyle(darkMapStyle);
              },
              markers: _gmMarkers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
            ),

            // --- BOUTON MA POSITION ---
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassStroke, width: 1),
                  boxShadow: Fx.glow,
                ),
                child: IconButton(
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Icon(
                          Icons.my_location,
                          size: 24,
                          color: _userLocation != null
                              ? AppColors.accent
                              : AppColors.text,
                        ),
                  onPressed: _isLoadingLocation ? null : _centerOnUser,
                ),
              ),
            ),

            // --- ERREUR LOCALISATION ---
            if (_locationError.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 16,
                right: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationError,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // --- PANNEAU DE RECHERCHE qui CHEVAUCHE la navbar (visuellement) ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0, // on laisse le verre passer SOUS la navbar
              child: StreamBuilder<List<Reservation>>(
                stream: _reservationService.getUserReservationsStream(
                  _reservationService.getCurrentUserId() ?? '',
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return PaneauRecherche(
                      selectedDestination: _selectedDestination,
                      onTap: _openLocationSearch,
                      noWrapper: true,
                    );
                  }
                  
                  final reservations = snapshot.data!;
                  
                  // Debug logs supprimés pour éviter le spam
                  
        final pendingOrWaitingReservations = reservations
            .where((r) => r.status == ReservationStatus.pending ||
                         r.status == ReservationStatus.confirmed)
            .toList();
                  
                  final hasPending = pendingOrWaitingReservations.isNotEmpty;

                  return GlassContainer(
                    // arrondis seulement en haut pour coller au bas de l'écran
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    // ⚠️ padding bas = safe area + hauteur navbar pour que le CONTENU reste au-dessus,
                    // tandis que le fond en verre continue derrière la navbar.
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: bottomSafe + kBottomNavigationBarHeight - 20, // espace pour la navbar et champ de recherche
                    ),
                    child: hasPending
                        ? _buildPendingReservationPanel(pendingOrWaitingReservations.first)
                        : PaneauRecherche(
                            selectedDestination: _selectedDestination,
                            onTap: _openLocationSearch,
                            noWrapper: true,
                          ),
                  );
                },
              ),
            ),
          ],
        ),

        // --- NAVBAR à la bonne position (inchangée partout) ---
        bottomNavigationBar: widget.showBottomBar
            ? CustomBottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              )
            : null,
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
        _showErrorSnackBar(AppLocalizations.of(context).adminPhoneNotAvailable);
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
        _showErrorSnackBar(AppLocalizations.of(context).adminPhoneNotAvailable);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'envoi du SMS: $e');
    }
  }

  // Afficher les détails de la réservation
  void _showReservationDetail(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationDetailScreen(
          reservation: reservation,
        ),
      ),
    );
  }

  // Annuler une réservation
  Future<void> _cancelReservation(Reservation reservation) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: AppLocalizations.of(context).cancelReservation,
      message: AppLocalizations.of(context).cancelReservationConfirmation,
      confirmText: AppLocalizations.of(context).yesCancel,
      cancelText: AppLocalizations.of(context).no,
      icon: Icons.cancel_outlined,
      iconColor: Colors.redAccent,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservation.id)
          .update({
        'status': 'cancelled',
        'lastUpdated': Timestamp.now(),
        'cancelledAt': Timestamp.now(),
        'cancelledBy': 'client',
        'cancellationReason': 'Annulé par le ${AppLocalizations.of(context).client}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).reservationCancelledSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorCancelling(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Afficher un message d'erreur
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.hot,
        ),
      );
    }
  }
}
