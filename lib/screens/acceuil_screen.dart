import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localisation_recherche_screen.dart';
import '../theme/theme_app.dart';
import '../widgets/widget_navBar.dart';
import '../widgets/paneau_recherche.dart';

class AccueilScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const AccueilScreen({super.key, this.onNavigate});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final MapController _mapController = MapController();
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
      setState(() {
        _isLoadingLocation = true;
        _locationError = '';
      });

      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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
          setState(() {
            _locationError = 'Permission de localisation refusée';
            _isLoadingLocation = false;
          });
          _addDefaultLocationMarker();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
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

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _addUserLocationMarker();

      // Centrer la carte sur la position utilisateur
      _mapController.move(_userLocation!, 15.0);
    } catch (e) {
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
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
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
              border: Border.all(color: AppColors.background, width: 3),
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
      setState(() {
        _selectedDestination = result['address'];
        _destinationCoordinates = result['coordinates'];
      });

      if (_destinationCoordinates != null) {
        _addDestinationMarker(_destinationCoordinates!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

          Container(color: AppColors.background.withOpacity(0.1)),

          // BOUTON MA POSITION
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.background.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isLoadingLocation
                    ? SizedBox(
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
                            : AppColors.textSecondary,
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
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
          // Panneau bas avec design parfait
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PaneauRecherche(
              selectedDestination: _selectedDestination,
              onTap: _openLocationSearch,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
