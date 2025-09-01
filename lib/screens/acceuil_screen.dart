import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'localisation_recherche_screen.dart';
import '../theme/theme_app.dart'; // ✅ Import corrigé
import '../widgets/widget_navBar.dart';

// Pour Google Maps, remplacez les imports par :
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class AccueilScreen extends StatefulWidget {
  // ✅ Nom de classe corrigé (CamelCase)
  // Callback pour naviguer vers les autres écrans
  final Function(int)? onNavigate;

  const AccueilScreen({super.key, this.onNavigate});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final MapController _mapController = MapController();
  int _selectedIndex = 0; // Index 0 pour "Accueil" (actif)

  String? _selectedDestination;
  LatLng? _destinationCoordinates;

  // Marker pour la destination sélectionnée
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _addUserLocationMarker();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex)
      return; // Éviter la navigation si déjà sur la page

    setState(() {
      _selectedIndex = index;
    });

    // Navigation vers les autres écrans
    switch (index) {
      case 0: // Accueil (déjà sur cette page)
        break;
      case 1: // Trajets
        Navigator.pushReplacementNamed(context, '/trajets');
        break;
      case 2: // Compte
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _addUserLocationMarker() {
    // Position par défaut (vous pouvez utiliser la géolocalisation)
    final userLocation = LatLng(48.8566, 2.3522); // Paris

    setState(() {
      _markers.add(
        Marker(
          point: userLocation,
          width: 40, // ✅ Taille augmentée pour meilleure visibilité
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accent, // ✅ Couleur accent au lieu de bleu
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.background, // ✅ Bordure sombre
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.black, // ✅ Icône noire sur fond accent
              size: 20,
            ),
          ),
        ),
      );
    });
  }

  void _addDestinationMarker(LatLng destination) {
    setState(() {
      // Supprimer l'ancien marker de destination s'il existe
      _markers.removeWhere((marker) => marker.point != LatLng(48.8566, 2.3522));

      // Ajouter le nouveau marker - THÉMATISÉ
      _markers.add(
        Marker(
          point: destination,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF4444), // ✅ Rouge vif pour destination
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.background, // ✅ Bordure sombre
                width: 3,
              ),
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

    // Centrer la carte pour voir les deux points
    _fitMapToShowBothMarkers(destination);
  }

  void _fitMapToShowBothMarkers(LatLng destination) {
    final userLocation = LatLng(48.8566, 2.3522);
    final bounds = LatLngBounds.fromPoints([userLocation, destination]);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
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
      backgroundColor: AppColors.background, // ✅ Background noir
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      body: Stack(
        children: [
          // Carte Flutter Map - THÉMATISÉE SOMBRE
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522),
              initialZoom: 14.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              // ✅ TILE LAYER SOMBRE - Thème dark
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.my_mobility_services',
                maxZoom: 19,
                // Options pour le thème sombre
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors © CARTO',
                },
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Overlay sombre léger pour uniformiser
          Container(color: AppColors.background.withOpacity(0.1)),

          // Bouton menu en haut à gauche - THÉMATISÉ
          if (widget.onNavigate == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface, // ✅ Surface sombre
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
                  icon: Icon(
                    Icons.menu,
                    size: 24,
                    color: AppColors.accent, // ✅ Couleur accent
                  ),
                  onPressed: _openDrawer,
                ),
              ),
            ),

          // Titre principal - THÉMATISÉ
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(
                  0.9,
                ), // ✅ Background semi-transparent
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.background.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'On vous emmène !',
                style: TextStyle(
                  color: Colors.white, // ✅ Texte blanc
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: AppColors.accent.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Zone de saisie en bas - THÉMATISÉE
          Positioned(
            bottom: widget.onNavigate != null ? 120 : 200,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _openLocationSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface, // ✅ Surface sombre
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent, // ✅ Bordure accent
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.background.withOpacity(0.8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppColors.accent, // ✅ Icône accent
                      size: 26,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedDestination ?? 'Où allez-vous ?',
                        style: TextStyle(
                          color: _selectedDestination != null
                              ? Colors
                                    .white // ✅ Texte blanc si sélectionné
                              : AppColors
                                    .textSecondary, // ✅ Texte secondaire sinon
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary,
                      size: 16,
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
}
