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
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/admin_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    } else {
      switch (index) {
        case 1:
          Navigator.pushReplacementNamed(context, '/trajets');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/profile');
          break;
      }
    }
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
          _locationError = 'Services de localisation désactivés';
          _isLoadingLocation = false;
        });
        _addDefaultLocationMarker();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationError = 'Permission de localisation refusée';
            _isLoadingLocation = false;
          });
          _addDefaultLocationMarker();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Permission de localisation refusée définitivement';
          _isLoadingLocation = false;
        });
        _addDefaultLocationMarker();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
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
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réservation en attente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'En attente de confirmation du chauffeur',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
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
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'En attente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
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
                    Text(
                      reservation.vehicleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        '${reservation.totalPrice.toStringAsFixed(1)} €',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
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
                    Text(
                      '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
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
          ),
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
          const SizedBox(height: 16),
          // Boutons de contact pour les réservations en attente
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
      ),
    );
  }

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
                stream: _reservationService.getUserPendingReservationsStream(),
                builder: (context, snapshot) {
                  final hasPending =
                      snapshot.hasData && snapshot.data!.isNotEmpty;

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
                        ? _buildPendingReservationPanel(snapshot.data!.first)
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
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.hot,
        ),
      );
    }
  }
}
