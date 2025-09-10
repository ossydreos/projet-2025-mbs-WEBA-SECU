import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/theme/google_map_styles.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/scheduling_screen.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';
import 'package:my_mobility_services/data/services/vehicle_service.dart';
import 'package:my_mobility_services/data/services/directions_service.dart';

class BookingScreen extends StatefulWidget {
  final String departure;
  final String destination;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;

  const BookingScreen({
    super.key,
    required this.departure,
    required this.destination,
    this.departureCoordinates,
    this.destinationCoordinates,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with TickerProviderStateMixin {
  gmaps.GoogleMapController? _googleMapController;
  VehiculeType? _selectedVehicle;
  int _selectedIndex = 0;
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  bool _isPanelExpanded = true;
  double _currentPanelHeight = 0.0;
  double _dragStartHeight = 0.0;
  
  // Service et données des véhicules
  final VehicleService _vehicleService = VehicleService();
  List<VehiculeType> _vehicles = [];
  bool _isLoadingVehicles = true;
  double _estimatedDistance = 0.0; // Distance estimée en km
  String _estimatedArrival = 'Arrivée d\'ici 10:13'; // Estimation d'arrivée
  List<gmaps.LatLng> _routePoints = []; // Points de la route réelle

  @override
  void initState() {
    super.initState();
    // Contrôleur Google Maps créé via onMapCreated

    // Initialiser l'animation du panneau
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _panelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeInOut),
    );

    // Par défaut, le panneau est étendu
    _panelController.forward();

    // Charger les véhicules depuis la base de données
    _loadVehicles();
    
    // Calculer la distance et l'heure d'arrivée estimées
    _calculateEstimatedDistanceAndArrival();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnRoute();
    });
  }

  @override
  void didUpdateWidget(BookingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculer si les coordonnées ont changé
    if (oldWidget.departureCoordinates != widget.departureCoordinates ||
        oldWidget.destinationCoordinates != widget.destinationCoordinates) {
      _calculateEstimatedDistanceAndArrival();
    }
  }

  // Charger les véhicules depuis la base de données
  Future<void> _loadVehicles() async {
    try {
      final vehicles = await _vehicleService.getActiveVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoadingVehicles = false;
        // Sélectionner le premier véhicule par défaut
        if (_vehicles.isNotEmpty) {
          _selectedVehicle = _vehicles.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingVehicles = false;
      });
    }
  }

  // Calculer la distance et l'heure d'arrivée estimées
  Future<void> _calculateEstimatedDistanceAndArrival() async {
    if (widget.departureCoordinates != null && widget.destinationCoordinates != null) {
      try {
        // Utiliser l'API Google Maps pour une estimation précise
        final distance = await DirectionsService.getRealDistance(
          origin: widget.departureCoordinates!,
          destination: widget.destinationCoordinates!,
        );
        
        final arrivalTime = await DirectionsService.getEstimatedArrivalTime(
          origin: widget.departureCoordinates!,
          destination: widget.destinationCoordinates!,
        );
        
        setState(() {
          _estimatedDistance = distance < 1.0 ? 1.0 : distance; // Distance minimum de 1km
          _estimatedArrival = arrivalTime;
        });
        
        // Mettre à jour le tracé de la route
        _updateRoutePolyline();
      } catch (e) {
        // Pas de fallback - l'API doit fonctionner
        setState(() {
          _estimatedDistance = 0.0;
          _estimatedArrival = 'Erreur de calcul';
        });
      }
    } else {
      // Distance par défaut si pas de coordonnées
      _estimatedDistance = 5.0;
      _estimatedArrival = 'Temps estimé 15 min';
    }
  }


  // Mettre à jour le tracé de la route avec Google Maps
  Future<void> _updateRoutePolyline() async {
    if (widget.departureCoordinates != null && widget.destinationCoordinates != null) {
      try {
        final directions = await DirectionsService.getDirections(
          origin: widget.departureCoordinates!,
          destination: widget.destinationCoordinates!,
        );
        
        if (directions != null && directions['polyline'] != null) {
          // Décoder la polyline de Google Maps
          _routePoints = _decodePolyline(directions['polyline']);
          
          // Forcer la mise à jour de l'UI
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        // Erreur silencieuse
      }
    }
  }

  // Décoder la polyline de Google Maps
  List<gmaps.LatLng> _decodePolyline(String polyline) {
    List<gmaps.LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(gmaps.LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _centerMapOnRoute() {
    // Utiliser les vraies coordonnées si disponibles, sinon utiliser des coordonnées par défaut
    final departure = widget.departureCoordinates ?? LatLng(48.8566, 2.3522);
    final destination =
        widget.destinationCoordinates ?? LatLng(48.8584, 2.2945);

    // Calculer le centre entre les deux points
    final centerLat = (departure.latitude + destination.latitude) / 2;
    final centerLng = (departure.longitude + destination.longitude) / 2;

    // Calculer le zoom pour que les deux points soient visibles
    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        departure.latitude < destination.latitude
            ? departure.latitude
            : destination.latitude,
        departure.longitude < destination.longitude
            ? departure.longitude
            : destination.longitude,
      ),
      northeast: gmaps.LatLng(
        departure.latitude > destination.latitude
            ? departure.latitude
            : destination.latitude,
        departure.longitude > destination.longitude
            ? departure.longitude
            : destination.longitude,
      ),
    );
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.pushReplacementNamed(context, '/trajets');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _selectVehicle(VehiculeType vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
    });
  }

  // Obtenir la couleur du véhicule selon sa catégorie
  Color _getVehicleColor(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.economique:
        return AppColors.accent;
      case VehicleCategory.van:
        return Colors.blue;
      case VehicleCategory.luxe:
        return Colors.amber;
    }
  }


  void _togglePanel() {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final minHeight = screenHeight * 0.45;
    final maxHeight = screenHeight * 0.72;
    setState(() {
      final midpoint = (minHeight + maxHeight) / 2;
      _currentPanelHeight = _currentPanelHeight >= midpoint
          ? minHeight
          : maxHeight;
      _isPanelExpanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final panelExpandedHeight =
        screenHeight * 0.45; // 45% de l'écran (min souhaité)
    final panelCollapsedHeight =
        screenHeight * 0.45; // même valeur pour éviter de descendre plus bas

    // Initialiser la hauteur du panneau si pas encore fait
    if (_currentPanelHeight == 0.0) {
      _currentPanelHeight = panelExpandedHeight;
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Carte en arrière-plan
            Positioned.fill(
              child: Column(
                children: [
                  // Header compact avec adresses
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${widget.departure} → ${widget.destination}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Icon(Icons.add, size: 24, color: Colors.white),
                      ],
                    ),
                  ),

                  // Carte
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: gmaps.GoogleMap(
                          initialCameraPosition: const gmaps.CameraPosition(
                            target: gmaps.LatLng(48.8566, 2.3522),
                            zoom: 12.0,
                          ),
                          onMapCreated: (controller) {
                            _googleMapController = controller;
                            controller.setMapStyle(darkMapStyle);
                            _centerMapOnRoute();
                          },
                          markers: {
                            gmaps.Marker(
                              markerId: const gmaps.MarkerId('departure'),
                              position: gmaps.LatLng(
                                (widget.departureCoordinates ??
                                        const LatLng(48.8566, 2.3522))
                                    .latitude,
                                (widget.departureCoordinates ??
                                        const LatLng(48.8566, 2.3522))
                                    .longitude,
                              ),
                              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                                gmaps.BitmapDescriptor.hueAzure,
                              ),
                            ),
                            gmaps.Marker(
                              markerId: const gmaps.MarkerId('destination'),
                              position: gmaps.LatLng(
                                (widget.destinationCoordinates ??
                                        const LatLng(48.8584, 2.2945))
                                    .latitude,
                                (widget.destinationCoordinates ??
                                        const LatLng(48.8584, 2.2945))
                                    .longitude,
                              ),
                              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                                gmaps.BitmapDescriptor.hueRed,
                              ),
                            ),
                          },
                          polylines: _routePoints.isNotEmpty
                              ? {
                                  gmaps.Polyline(
                                    polylineId: const gmaps.PolylineId('route'),
                                    color: Colors.blue,
                                    width: 4,
                                    points: _routePoints,
                                  ),
                                }
                              : {
                                  // Fallback en ligne droite si pas de route
                                  gmaps.Polyline(
                                    polylineId: const gmaps.PolylineId('route'),
                                    color: Colors.blue,
                                    width: 4,
                                    points: [
                                      gmaps.LatLng(
                                        (widget.departureCoordinates ??
                                                const LatLng(48.8566, 2.3522))
                                            .latitude,
                                        (widget.departureCoordinates ??
                                                const LatLng(48.8566, 2.3522))
                                            .longitude,
                                      ),
                                      gmaps.LatLng(
                                        (widget.destinationCoordinates ??
                                                const LatLng(48.8584, 2.2945))
                                            .latitude,
                                        (widget.destinationCoordinates ??
                                                const LatLng(48.8584, 2.2945))
                                            .longitude,
                                      ),
                                    ],
                                  ),
                                },
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Panneau coulissant - STYLE BOLT EXACT
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  // Pas de gestion de pan pour simplifier
                },
                onPanUpdate: (details) {
                  // Pas de gestion de pan pour simplifier
                },
                onPanEnd: (details) {
                  // Pas de gestion de pan pour simplifier
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: _isPanelExpanded
                      ? panelExpandedHeight
                      : panelCollapsedHeight,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: GlassContainer(
                    borderRadius: const BorderRadius.only(
                      topLeft: Fx.radiusM,
                      topRight: Fx.radiusM,
                    ),
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        // Handle pour glisser
                        GestureDetector(
                          onTap: _togglePanel,
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.text,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        if (_isPanelExpanded) ...[
                          // Header du panneau étendu
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  'Véhicules disponibles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _estimatedArrival,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.bg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Liste des véhicules - STYLE BOLT
                          Expanded(
                            child: _isLoadingVehicles
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                    ),
                                  )
                                : _vehicles.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.car_rental,
                                              size: 64,
                                              color: AppColors.textWeak,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucun véhicule disponible',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: AppColors.textWeak,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Veuillez réessayer plus tard',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textWeak,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                        itemCount: _vehicles.length,
                                        itemBuilder: (context, index) {
                                      final vehicle = _vehicles[index];
                                      final isSelected = _selectedVehicle?.id == vehicle.id;
                                      final estimatedPrice = _vehicleService.calculateTripPrice(vehicle, _estimatedDistance);
                                      

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.accent.withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.accent
                                                : AppColors.glassStroke,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          onTap: () => _selectVehicle(vehicle),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _getVehicleColor(vehicle.category).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              vehicle.icon,
                                              color: _getVehicleColor(vehicle.category),
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            vehicle.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.accent
                                                  : Colors.white,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                size: 14,
                                                color: AppColors.text,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                vehicle.capacityDisplay,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.luggage,
                                                size: 14,
                                                color: AppColors.text,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                vehicle.luggageDisplay,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Text(
                                            '${estimatedPrice.toStringAsFixed(2)} €',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.accent
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ] else ...[
                          // Panneau réduit - STYLE BOLT EXACT
                          if (_selectedVehicle != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getVehicleColor(_selectedVehicle!.category).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _selectedVehicle!.icon,
                                      color: _getVehicleColor(_selectedVehicle!.category),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _selectedVehicle!.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _selectedVehicle!.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${_vehicleService.calculateTripPrice(_selectedVehicle!, _estimatedDistance).toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // Footer avec bouton de réservation - STYLE BOLT EXACT
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            8 + safeAreaBottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Méthode de paiement
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      color: AppColors.bg,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Espèces',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.text,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Bouton de réservation - STYLE BOLT EXACT
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _selectedVehicle != null ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SchedulingScreen(
                                          vehicleName: _selectedVehicle!.name,
                                          departure: widget.departure,
                                          destination: widget.destination,
                                          departureCoordinates:
                                              widget.departureCoordinates,
                                          destinationCoordinates:
                                              widget.destinationCoordinates,
                                        ),
                                      ),
                                    );
                                  } : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: AppColors.bg,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _selectedVehicle != null 
                                        ? 'Planifier ${_selectedVehicle!.name}'
                                        : 'Sélectionner un véhicule',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
              ),
            ),
          ],
        ),
        // Pas de bottomNavigationBar - le bouton "Sélectionner" la remplace
      ),
    );
  }
}
