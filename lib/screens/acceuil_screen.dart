import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localisation_recherche_screen.dart';
import 'booking_screen.dart';
import '../ui/glass/glassmorphism_theme.dart';
import '../widgets/widget_navBar.dart';
import '../widgets/paneau_recherche.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';

class AccueilScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const AccueilScreen({super.key, this.onNavigate});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final MapController _mapController = MapController();
  final ReservationService _reservationService = ReservationService();
  int _selectedIndex = 0;

  String? _selectedDestination;
  LatLng? _destinationCoordinates;
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  String _locationError = '';

  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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

      // Vérifier si les services de localisation sont activés
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

      // Vérifier les permissions
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

      // Récupérer la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _addUserLocationMarker();

      // Centrer la carte sur la position utilisateur
      _mapController.move(_userLocation!, 15.0);
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

    setState(() {
      // Supprimer l'ancien marker utilisateur
      _markers.removeWhere(
        (marker) =>
            marker.point == _userLocation ||
            marker.point == LatLng(48.8566, 2.3522),
      );

      _markers.add(
        Marker(
          point: userLocation,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Brand.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Brand.bg, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Brand.accent.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _userLocation != null ? Icons.my_location : Icons.person,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      );
    });
  }

  void _addDefaultLocationMarker() {
    setState(() {
      _userLocation = LatLng(48.8566, 2.3522); // Paris par défaut
    });
    _addUserLocationMarker();
  }

  void _addDestinationMarker(LatLng destination) {
    setState(() {
      // Supprimer l'ancien marker de destination s'il existe
      _markers.removeWhere(
        (marker) =>
            marker.point != _userLocation &&
            marker.point != LatLng(48.8566, 2.3522),
      );

      _markers.add(
        Marker(
          point: destination,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF4444),
              shape: BoxShape.circle,
              border: Border.all(color: Brand.bg, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4444).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
        ),
      );
    });

    _fitMapToShowBothMarkers(destination);
  }

  void _fitMapToShowBothMarkers(LatLng destination) {
    final userLocation = _userLocation ?? LatLng(48.8566, 2.3522);
    final bounds = LatLngBounds.fromPoints([userLocation, destination]);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    } else {
      _getUserLocation(); // Réessayer la localisation
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
      // Si on a les deux adresses (départ et destination), ouvrir la page de réservation
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
        // Ancien comportement pour la destination uniquement
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réservation en attente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'En attente de confirmation du chauffeur',
                      style: TextStyle(
                        fontSize: 14,
                        color: Brand.text,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
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
          
          // Détails de la réservation
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Véhicule et prix
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Brand.accent,
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
                    Text(
                      '${reservation.totalPrice.toStringAsFixed(1)} €',
                      style: TextStyle(
                        fontSize: 18,
                        color: Brand.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Itinéraire
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Brand.accent,
                      size: 16,
                    ),
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
                
                // Date et heure
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Brand.text,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${reservation.selectedDate.day}/${reservation.selectedDate.month} à ${reservation.selectedTime}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Brand.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Message d'information
          GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre réservation est en cours de traitement. Vous ne pouvez pas faire une nouvelle réservation tant qu\'elle n\'est pas confirmée.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
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
    return GlassBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // CARTE AVEC POSITION UTILISATEUR
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(48.8566, 2.3522),
              initialZoom: _userLocation != null ? 15.0 : 14.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.my_mobility_services',
                maxZoom: 19,
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          Container(color: Colors.transparent),

          // BOUTON MA POSITION
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Brand.glass,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Brand.glassStroke,
                  width: 1,
                ),
                boxShadow: Fx.glow,
              ),
              child: IconButton(
                icon: _isLoadingLocation
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Brand.accent,
                        ),
                      )
                    : Icon(
                        Icons.my_location,
                        size: 24,
                        color: _userLocation != null
                            ? Brand.accent
                            : Brand.text,
                      ),
                onPressed: _isLoadingLocation ? null : _centerOnUser,
              ),
            ),
          ),

          // AFFICHAGE D'ERREUR SI PROBLÈME DE LOCALISATION
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
          // Panneau bas - Réservation en attente ou panneau de recherche
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<List<Reservation>>(
              stream: _reservationService.getUserPendingReservationsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // Afficher les détails de la réservation en attente
                  return _buildPendingReservationPanel(snapshot.data!.first);
                } else {
                  // Version "MAGNIFIQUE" : un seul conteneur verre contenant panneau + nav intégrée
                  return Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    child: GlassContainer(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PaneauRecherche(
                            selectedDestination: _selectedDestination,
                            onTap: _openLocationSearch,
                            noWrapper: true,
                          ),
                          const SizedBox(height: 10),
                          CustomBottomNavigationBar(
                            currentIndex: _selectedIndex,
                            onTap: _onItemTapped,
                            noWrapper: true,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    ));
  }
}
