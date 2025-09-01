import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'localisation_recherche_screen.dart';
import '../theme/theme_app.dart';

// Pour Google Maps, remplacez les imports par :
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleReservationScreen extends StatefulWidget {
  // Callback pour naviguer vers les autres écrans
  final Function(int)? onNavigate;

  const VehicleReservationScreen({super.key, this.onNavigate});

  @override
  State<VehicleReservationScreen> createState() =>
      _VehicleReservationScreenState();
}

class _VehicleReservationScreenState extends State<VehicleReservationScreen> {
  final MapController _mapController = MapController();

  // Pour Google Maps, remplacez par :
  // GoogleMapController? _googleMapController;

  String? _selectedDestination;
  LatLng? _destinationCoordinates;

  // Marker pour la destination sélectionnée
  List<Marker> _markers = [];

  // Pour Google Maps, remplacez par :
  // Set<Marker> _googleMarkers = {};

  @override
  void initState() {
    super.initState();
    _addUserLocationMarker();
  }

  void _addUserLocationMarker() {
    // Position par défaut (vous pouvez utiliser la géolocalisation)
    final userLocation = LatLng(48.8566, 2.3522); // Paris

    setState(() {
      _markers.add(
        Marker(
          point: userLocation,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ),
      );
    });

    // Pour Google Maps, remplacez par :
    /*
    _googleMarkers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(48.8566, 2.3522),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    */
  }

  void _addDestinationMarker(LatLng destination) {
    setState(() {
      // Supprimer l'ancien marker de destination s'il existe
      _markers.removeWhere((marker) => marker.point != LatLng(48.8566, 2.3522));

      // Ajouter le nouveau marker
      _markers.add(
        Marker(
          point: destination,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 16),
          ),
        ),
      );
    });

    // Centrer la carte pour voir les deux points
    _fitMapToShowBothMarkers(destination);

    // Pour Google Maps, remplacez par :
    /*
    _googleMarkers.removeWhere((marker) => marker.markerId.value == 'destination');
    _googleMarkers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    setState(() {});
    */
  }

  void _fitMapToShowBothMarkers(LatLng destination) {
    final userLocation = LatLng(48.8566, 2.3522);
    final bounds = LatLngBounds.fromPoints([userLocation, destination]);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );

    // Pour Google Maps, remplacez par :
    /*
    if (_googleMapController != null) {
      _googleMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              math.min(userLocation.latitude, destination.latitude),
              math.min(userLocation.longitude, destination.longitude),
            ),
            northeast: LatLng(
              math.max(userLocation.latitude, destination.latitude),
              math.max(userLocation.longitude, destination.longitude),
            ),
          ),
          100.0, // padding
        ),
      );
    }
    */
  }

  void _openLocationSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationSearchScreen(currentDestination: _selectedDestination),
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

  void _openDrawer() {
    // Si on est dans main_screen, ouvrir le drawer
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Carte Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522),
              initialZoom: 14.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.my_mobility_services',
                maxZoom: 19,
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Pour Google Maps, remplacez la FlutterMap par :
          /*
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _googleMapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(48.8566, 2.3522),
              zoom: 14.0,
            ),
            markers: _googleMarkers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          */

          // Bouton menu en haut à gauche (seulement si pas dans main_screen)
          if (widget.onNavigate == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, size: 20),
                  onPressed: _openDrawer,
                ),
              ),
            ),

          // Titre principal
          const Positioned(
            top: 100,
            left: 20,
            child: Text(
              'On vous emmène !',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Zone de saisie en bas
          Positioned(
            bottom: widget.onNavigate != null
                ? 120
                : 200, // Adjust based on navigation
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _openLocationSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDestination ?? 'Où allez-vous ?',
                      style: TextStyle(
                        color: _selectedDestination != null
                            ? Colors.black
                            : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barre de navigation en bas (seulement si pas dans main_screen)
          if (widget.onNavigate == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80 + MediaQuery.of(context).padding.bottom,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                    top: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.home,
                        label: 'Accueil',
                        isActive: true,
                        onTap: () {}, // Déjà sur accueil
                      ),
                      _buildNavItem(
                        icon: Icons.calendar_today,
                        label: 'Trajets',
                        isActive: false,
                        onTap: () {
                          // Navigation vers trajets
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(1);
                          }
                        },
                      ),
                      _buildNavItem(
                        icon: Icons.person,
                        label: 'Compte',
                        isActive: false,
                        onTap: () {
                          // 🎯 NAVIGATION VERS TON PROFIL
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(2);
                          } else {
                            // Si utilisé sans main_screen, navigation directe
                            Navigator.pushNamed(context, '/profile');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.black : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
