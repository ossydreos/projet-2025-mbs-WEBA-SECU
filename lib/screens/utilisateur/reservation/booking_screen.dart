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
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/services/custom_marker_service.dart';

class BookingScreen extends StatefulWidget {
  final String departure;
  final String destination;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;
  final bool fromSummary;

  const BookingScreen({
    super.key,
    required this.departure,
    required this.destination,
    this.departureCoordinates,
    this.destinationCoordinates,
    this.fromSummary = false,
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
  bool _isDragging = false;
  double _dragStartY = 0.0;

  // Service et données des véhicules
  final VehicleService _vehicleService = VehicleService();
  double _estimatedDistance = 0.0; // Distance estimée en km
  String _estimatedArrival = 'Estimated arrival 10:13'; // Will be translated dynamically
  List<gmaps.LatLng> _routePoints = []; // Points de la route réelle
  bool _isCalculating = true; // État de calcul en cours
  gmaps.BitmapDescriptor? _departureIcon;
  gmaps.BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _initializeCustomIcons();
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

    // Initialiser la hauteur du panneau à l'état étendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      _currentPanelHeight = screenHeight * 0.45; // Hauteur par défaut étendue
      _isPanelExpanded = true;
    });

    // Les véhicules sont maintenant chargés via StreamBuilder

    // ${AppLocalizations.of(context).calculateDistanceAndArrival}
    _calculateEstimatedDistanceAndArrival();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnRoute();
    });
  }

  Future<void> _initializeCustomIcons() async {
    _departureIcon = await CustomMarkerService.createDepartureIcon(
      customIconPath: 'assets/icons/taxi_1f695.png',
    );
    _destinationIcon = await CustomMarkerService.createDestinationIcon(
      customIconPath: 'assets/icons/Red_Pin_Emoji_large.webp',
    );
  }

  @override
  void didUpdateWidget(BookingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculer si les coordonnées ont changé
    if (oldWidget.departureCoordinates != widget.departureCoordinates ||
        oldWidget.destinationCoordinates != widget.destinationCoordinates) {
      _calculateEstimatedDistanceAndArrival();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnRoute();
      });
    }
  }


  // ${AppLocalizations.of(context).calculateDistanceAndArrival}
  Future<void> _calculateEstimatedDistanceAndArrival() async {
    if (widget.departureCoordinates != null &&
        widget.destinationCoordinates != null) {
      setState(() {
        _isCalculating = true;
      });
      
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
          _estimatedDistance = distance < 1.0
              ? 1.0
              : distance; // Distance minimum de 1km
          _estimatedArrival = arrivalTime;
          _isCalculating = false; // Calcul terminé
        });

        // Mettre à jour le tracé de la route
        _updateRoutePolyline();
      } catch (e) {
        // Pas de fallback - l'API doit fonctionner
        setState(() {
          _estimatedDistance = 0.0;
          _estimatedArrival = AppLocalizations.of(context).calculationError;
          _isCalculating = false; // Calcul terminé (avec erreur)
        });
      }
    } else {
      // Distance par défaut si pas de coordonnées
      setState(() {
        _estimatedDistance = 5.0;
        _estimatedArrival = AppLocalizations.of(context).estimatedTime;
        _isCalculating = false; // Pas de calcul nécessaire
      });
    }
  }

  // Mettre à jour le tracé de la route avec Google Maps
  Future<void> _updateRoutePolyline() async {
    if (widget.departureCoordinates != null &&
        widget.destinationCoordinates != null) {
      try {
        final directions = await DirectionsService.getDirections(
          origin: widget.departureCoordinates!,
          destination: widget.destinationCoordinates!,
        );

        if (directions != null && directions['polyline'] != null) {
          // ${AppLocalizations.of(context).decodePolyline}
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

  // Vérifier si le véhicule sélectionné est toujours disponible
  void _checkSelectedVehicleAvailability(List<VehiculeType> vehicles) {
    if (_selectedVehicle != null) {
      final selectedVehicleStillExists = vehicles.any((v) => v.id == _selectedVehicle!.id);
      final selectedVehicleStillActive = vehicles.any((v) => v.id == _selectedVehicle!.id && v.isActive);
      
      if (!selectedVehicleStillExists) {
        // Le véhicule n'existe plus du tout
        setState(() {
          _selectedVehicle = null;
        });
        _showVehicleUnavailableMessage();
      } else if (!selectedVehicleStillActive) {
        // Le véhicule existe mais n'est plus actif
        setState(() {
          _selectedVehicle = null;
        });
        _showVehicleDeactivatedMessage();
      }
    }
  }

  void _showVehicleUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).selectedVehicleNoLongerAvailable,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showVehicleDeactivatedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).selectedVehicleDeactivated,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Obtenir la couleur du véhicule selon sa catégorie
  Color _getVehicleColor(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.economique:
        return AppColors.accent; // Couleur principale de l'app
      case VehicleCategory.van:
        return AppColors.accent2; // Couleur secondaire de l'app
      case VehicleCategory.luxe:
        return AppColors.hot; // Couleur tertiaire de l'app
    }
  }

  void _togglePanel() {
    final screenHeight = MediaQuery.of(context).size.height;
    final minHeight = screenHeight * 0.45;
    final maxHeight = screenHeight * 0.72;
    setState(() {
      final midpoint = (minHeight + maxHeight) / 2;
      _currentPanelHeight = _currentPanelHeight >= midpoint
          ? minHeight
          : maxHeight;
      _isPanelExpanded = _currentPanelHeight >= midpoint;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartY = details.globalPosition.dy;
      _dragStartHeight = _currentPanelHeight;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final minHeight = screenHeight * 0.45;
    final maxHeight = screenHeight * 0.72;
    
    final deltaY = details.globalPosition.dy - _dragStartY;
    final newHeight = _dragStartHeight - deltaY;
    
    setState(() {
      _currentPanelHeight = newHeight.clamp(minHeight, maxHeight);
      _isPanelExpanded = _currentPanelHeight >= (minHeight + maxHeight) / 2;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final minHeight = screenHeight * 0.45;
    final maxHeight = screenHeight * 0.72;
    final midpoint = (minHeight + maxHeight) / 2;
    
    setState(() {
      _isDragging = false;
      
      // Animation vers la position finale basée sur la vitesse et la position
      final velocity = details.velocity.pixelsPerSecond.dy;
      
      if (velocity.abs() > 500) {
        // Glissement rapide - aller vers la direction du mouvement
        if (velocity > 0) {
          // Glissement vers le bas - réduire
          _currentPanelHeight = minHeight;
          _isPanelExpanded = false;
        } else {
          // Glissement vers le haut - étendre
          _currentPanelHeight = maxHeight;
          _isPanelExpanded = true;
        }
      } else {
        // Glissement lent - aller vers la position la plus proche
        if (_currentPanelHeight >= midpoint) {
          _currentPanelHeight = maxHeight;
          _isPanelExpanded = true;
        } else {
          _currentPanelHeight = minHeight;
          _isPanelExpanded = false;
        }
      }
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
                              markerId: gmaps.MarkerId(AppLocalizations.of(context).departureMarker),
                              position: gmaps.LatLng(
                                (widget.departureCoordinates ??
                                        const LatLng(48.8566, 2.3522))
                                    .latitude,
                                (widget.departureCoordinates ??
                                        const LatLng(48.8566, 2.3522))
                                    .longitude,
                              ),
                              icon: _departureIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                                gmaps.BitmapDescriptor.hueAzure,
                              ),
                            ),
                            gmaps.Marker(
                              markerId: gmaps.MarkerId(AppLocalizations.of(context).destinationMarker),
                              position: gmaps.LatLng(
                                (widget.destinationCoordinates ??
                                        const LatLng(48.8584, 2.2945))
                                    .latitude,
                                (widget.destinationCoordinates ??
                                        const LatLng(48.8584, 2.2945))
                                    .longitude,
                              ),
                              icon: _destinationIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                                gmaps.BitmapDescriptor.hueRed,
                              ),
                            ),
                          },
                          polylines: _routePoints.isNotEmpty
                              ? {
                                  gmaps.Polyline(
                                    polylineId: gmaps.PolylineId(AppLocalizations.of(context).routePolyline),
                                    color: Colors.blue,
                                    width: 4,
                                    points: _routePoints,
                                  ),
                                }
                              : {
                                  // Fallback en ligne droite si pas de route
                                  gmaps.Polyline(
                                    polylineId: gmaps.PolylineId(AppLocalizations.of(context).routePolyline),
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
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: AnimatedContainer(
                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: _currentPanelHeight,
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

                        if (_currentPanelHeight >= (screenHeight * 0.40)) ...[
                          // Header du panneau étendu
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context).availableVehicles,
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
                                    color: _isCalculating ? Colors.orange : AppColors.accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isCalculating) ...[
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.bg,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        _isCalculating ? 'Calcul...' : _estimatedArrival,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.bg,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Liste des véhicules - STYLE BOLT avec StreamBuilder
                          Expanded(
                            child: StreamBuilder<List<VehiculeType>>(
                              stream: _vehicleService.getVehiclesStream(),
                              initialData: <VehiculeType>[],
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(
                                          color: AppColors.accent,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context).loadingVehicles,
                                          style: TextStyle(
                                            color: AppColors.textStrong,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context).loadingError,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textStrong,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context).pleaseRetry,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final vehicles = snapshot.data ?? [];
                                
                                // Vérifier si le véhicule sélectionné est toujours disponible (après le build)
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _checkSelectedVehicleAvailability(vehicles);
                                });
                                
                                // Trier les véhicules : actifs en haut, inactifs en bas
                                final sortedVehicles = List<VehiculeType>.from(vehicles)
                                  ..sort((a, b) {
                                    // Actifs d'abord (isActive = true), puis inactifs (isActive = false)
                                    if (a.isActive && !b.isActive) return -1;
                                    if (!a.isActive && b.isActive) return 1;
                                    return 0; // Même statut, garder l'ordre original
                                  });
                                
                                if (sortedVehicles.isEmpty) {
                                  return Center(
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
                                          AppLocalizations.of(context).noVehicleAvailable,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textStrong,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context).pleaseRetryLater,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Ne pas sélectionner automatiquement de véhicule
                                // L'utilisateur doit choisir manuellement

                                return ListView.builder(
                                  key: ValueKey('vehicles_${sortedVehicles.length}'),
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                  itemCount: sortedVehicles.length,
                                  itemBuilder: (context, index) {
                                    final vehicle = sortedVehicles[index];
                                    final isSelected = _selectedVehicle?.id == vehicle.id;
                                    final isActive = vehicle.isActive;
                                    final estimatedPrice = _vehicleService.calculateTripPrice(
                                      vehicle,
                                      _estimatedDistance,
                                    );
                                    // ✅ Arrondir à 0.05 CHF près
                                    final roundedPrice = (estimatedPrice * 20).round() / 20;

                                    return Opacity(
                                      opacity: isActive ? 1.0 : 0.5,
                                      child: Container(
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
                                        onTap: isActive ? () => _selectVehicle(vehicle) : null,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _getVehicleColor(vehicle.category)
                                                  .withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              vehicle.icon,
                                              color: _getVehicleColor(vehicle.category),
                                              size: 20,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  vehicle.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? AppColors.accent
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    size: 14,
                                                    color: AppColors.textStrong,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      vehicle.capacityDisplay,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textStrong,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(
                                                    Icons.luggage,
                                                    size: 14,
                                                    color: AppColors.textStrong,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      vehicle.luggageDisplay,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textStrong,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                vehicle.category.categoryInFrench,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: _getVehicleColor(vehicle.category),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? _getVehicleColor(vehicle.category).withOpacity(0.2)
                                                  : AppColors.glass,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? _getVehicleColor(vehicle.category)
                                                    : AppColors.glassStroke,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              '${roundedPrice.toStringAsFixed(2)} CHF',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? _getVehicleColor(vehicle.category)
                                                    : AppColors.textStrong,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
                                      color: _getVehicleColor(
                                        _selectedVehicle!.category,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _selectedVehicle!.icon,
                                      color: _getVehicleColor(
                                        _selectedVehicle!.category,
                                      ),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          _selectedVehicle!.category.categoryInFrench,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textStrong,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${((_vehicleService.calculateTripPrice(_selectedVehicle!, _estimatedDistance) * 20).round() / 20).toStringAsFixed(2)} CHF',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
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
                              // Bouton de réservation - STYLE BOLT EXACT
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: (_selectedVehicle != null && !_isCalculating && _estimatedDistance > 0)
                                      ? () {
                                          if (_selectedVehicle != null) {
                                            if (widget.fromSummary) {
                                              // Retourner au résumé avec les données mises à jour
                                              Navigator.pop(context, {
                                                'departure': widget.departure,
                                                'destination': widget.destination,
                                                'departureCoordinates': widget.departureCoordinates,
                                                'destinationCoordinates': widget.destinationCoordinates,
                                                'vehicleName': _selectedVehicle!.name,
                                              });
                                            } else {
                                              // Aller à la page de planification
                                              final calculatedPrice = _vehicleService.calculateTripPrice(
                                                _selectedVehicle!,
                                                _estimatedDistance,
                                              );
                                              // ✅ Arrondir à 0.05 CHF près
                                              final roundedPrice = (calculatedPrice * 20).round() / 20;
                                              print('🔥 DEBUG BOOKING: Prix calculé = $calculatedPrice');
                                              print('🔥 DEBUG BOOKING: Prix arrondi = $roundedPrice');
                                              print('🔥 DEBUG BOOKING: Véhicule = ${_selectedVehicle!.name}');
                                              print('🔥 DEBUG BOOKING: Distance = $_estimatedDistance');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SchedulingScreen(
                                                        vehicleName:
                                                            _selectedVehicle!.name,
                                                        departure: widget.departure,
                                                        destination:
                                                            widget.destination,
                                                        departureCoordinates: widget
                                                            .departureCoordinates,
                                                        destinationCoordinates: widget
                                                            .destinationCoordinates,
                                                        calculatedPrice: roundedPrice, // ✅ TRANSMETTRE LE PRIX ARRONDI
                                                      ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (_selectedVehicle != null && !_isCalculating && _estimatedDistance > 0)
                                        ? AppColors.accent
                                        : Colors.grey,
                                    foregroundColor: AppColors.bg,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isCalculating) ...[
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.bg,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        _isCalculating
                                            ? 'Calcul en cours...'
                                            : (_selectedVehicle != null
                                                ? (widget.fromSummary 
                                                    ? AppLocalizations.of(context).backToSummary
                                                    : AppLocalizations.of(context).planVehicle(_selectedVehicle!.name))
                                                : AppLocalizations.of(context).selectVehicle),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
