import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localisation_recherche_screen.dart';
import 'booking_screen.dart';
import '../ui/glass/glassmorphism_theme.dart';
import '../theme/google_map_styles.dart';
import '../widgets/widget_navBar.dart';
import '../widgets/paneau_recherche.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';

class AccueilScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const AccueilScreen({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> with AutomaticKeepAliveClientMixin {
  gmaps.GoogleMapController? _googleMapController;
  final ReservationService _reservationService = ReservationService();
  int _selectedIndex = 0;

  String? _selectedDestination;
  LatLng? _destinationCoordinates;
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  String _locationError = '';

  Set<gmaps.Marker> _gmMarkers = <gmaps.Marker>{};

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
    final userLocation = _userLocation ?? LatLng(48.8566, 2.3522);
    final marker = gmaps.Marker(
      markerId: const gmaps.MarkerId('user'),
      position: gmaps.LatLng(userLocation.latitude, userLocation.longitude),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
    );
    setState(() {
      _gmMarkers.removeWhere((m) => m.markerId == const gmaps.MarkerId('user'));
      _gmMarkers.add(marker);
    });
  }

  void _addDefaultLocationMarker() {
    setState(() {
      _userLocation = LatLng(48.8566, 2.3522);
    });
    _addUserLocationMarker();
  }

  void _addDestinationMarker(LatLng destination) {
    final marker = gmaps.Marker(
      markerId: const gmaps.MarkerId('destination'),
      position: gmaps.LatLng(destination.latitude, destination.longitude),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
    );
    setState(() {
      _gmMarkers.removeWhere((m) => m.markerId == const gmaps.MarkerId('destination'));
      _gmMarkers.add(marker);
    });
    _fitMapToShowBothMarkers(destination);
  }

  void _fitMapToShowBothMarkers(LatLng destination) {
    final user = _userLocation ?? LatLng(48.8566, 2.3522);
    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        user.latitude < destination.latitude ? user.latitude : destination.latitude,
        user.longitude < destination.longitude ? user.longitude : destination.longitude,
      ),
      northeast: gmaps.LatLng(
        user.latitude > destination.latitude ? user.latitude : destination.latitude,
        user.longitude > destination.longitude ? user.longitude : destination.longitude,
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
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
                child: const Icon(Icons.schedule, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Réservation en attente',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('En attente de confirmation du chauffeur',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('En attente',
                    style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
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
                    Icon(Icons.directions_car, color: Brand.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(reservation.vehicleName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    Text('${reservation.totalPrice.toStringAsFixed(1)} €',
                        style: TextStyle(fontSize: 18, color: Brand.accent, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Brand.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${reservation.departure} → ${reservation.destination}',
                          style: const TextStyle(fontSize: 14, color: Colors.white)),
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
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
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
                  (_userLocation ?? const LatLng(48.8566, 2.3522)).latitude,
                  (_userLocation ?? const LatLng(48.8566, 2.3522)).longitude,
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
                  color: Brand.glass,
                  shape: BoxShape.circle,
                  border: Border.all(color: Brand.glassStroke, width: 1),
                  boxShadow: Fx.glow,
                ),
                child: IconButton(
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Brand.accent),
                        )
                      : Icon(Icons.my_location,
                          size: 24, color: _userLocation != null ? Brand.accent : Brand.text),
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
                        child: Text(_locationError,
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                  final hasPending = snapshot.hasData && snapshot.data!.isNotEmpty;

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
                      bottom: bottomSafe + kBottomNavigationBarHeight + 8,
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
}