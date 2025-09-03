import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import '../theme/google_map_styles.dart';
import '../theme/theme_app.dart';
import '../ui/glass/glassmorphism_theme.dart';
import '../widgets/widget_navBar.dart';
import 'scheduling_screen.dart';

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
  String _selectedVehicle = 'Bolt';
  int _selectedIndex = 0;
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  bool _isPanelExpanded = true;
  double _currentPanelHeight = 0.0;

  // Données des véhicules en dur (sera remplacé par Firebase plus tard)
  final List<Map<String, dynamic>> _vehicles = [
    {
      'name': 'Bolt',
      'icon': Icons.directions_car,
      'time': '9 min',
      'passengers': '4',
      'price': '16,8 €',
      'description': 'Voitures de taille standard',
      'recommended': true,
      'color': AppColors.accent,
    },
    {
      'name': 'Comfort',
      'icon': Icons.directions_car,
      'time': '9 min',
      'passengers': '4',
      'price': '25,0 €',
      'description': 'Voitures confortables',
      'recommended': false,
      'color': Colors.grey,
    },
    {
      'name': 'Taxi',
      'icon': Icons.local_taxi,
      'time': '11 min',
      'passengers': '4',
      'price': '12,5–37,5 €',
      'description': 'Taxis traditionnels',
      'recommended': false,
      'color': Colors.yellow,
    },
    {
      'name': 'Green',
      'icon': Icons.electric_car,
      'time': '9 min',
      'passengers': '4',
      'price': '16,8 €',
      'description': 'Véhicules écologiques',
      'recommended': false,
      'color': Colors.green,
    },
    {
      'name': 'Women for women',
      'icon': Icons.person,
      'time': '12 min',
      'passengers': '4',
      'price': '21,6 €',
      'description': 'Conductrices femmes',
      'recommended': false,
      'color': Colors.orange,
    },
  ];

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnRoute();
    });
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

  void _selectVehicle(String vehicleName) {
    setState(() {
      _selectedVehicle = vehicleName;
    });
  }

  void _togglePanel() {
    setState(() {
      _isPanelExpanded = !_isPanelExpanded;
    });

    if (_isPanelExpanded) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final panelExpandedHeight = screenHeight * 0.45; // 45% de l'écran
    final panelCollapsedHeight =
        80.0 + safeAreaBottom; // Hauteur réduite + safe area

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
                          polylines: {
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
                              color: AppColors.textSecondary,
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
                                    color: Brand.accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Arrivée d\'ici 10:13',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Brand.bg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Liste des véhicules - STYLE BOLT
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              itemCount: _vehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = _vehicles[index];
                                final isSelected =
                                    _selectedVehicle == vehicle['name'];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Brand.accent.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Brand.accent
                                          : Brand.glassStroke,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () =>
                                        _selectVehicle(vehicle['name']),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: vehicle['color'].withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        vehicle['icon'],
                                        color: vehicle['color'],
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          vehicle['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Brand.accent
                                                : Colors.white,
                                          ),
                                        ),
                                        if (vehicle['recommended']) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Brand.accent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'RECOMMANDÉ',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: Brand.bg,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Brand.text,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          vehicle['time'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Brand.text,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Brand.text,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          vehicle['passengers'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Brand.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      vehicle['price'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Brand.accent
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
                                    color: _vehicles
                                        .firstWhere(
                                          (v) => v['name'] == _selectedVehicle,
                                        )['color']
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _vehicles.firstWhere(
                                      (v) => v['name'] == _selectedVehicle,
                                    )['icon'],
                                    color: _vehicles.firstWhere(
                                      (v) => v['name'] == _selectedVehicle,
                                    )['color'],
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
                                        _selectedVehicle,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _vehicles.firstWhere(
                                          (v) => v['name'] == _selectedVehicle,
                                        )['description'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _vehicles.firstWhere(
                                    (v) => v['name'] == _selectedVehicle,
                                  )['price'],
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
                                      color: Brand.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      color: Brand.bg,
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
                                    color: Brand.text,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Bouton de réservation - STYLE BOLT EXACT
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SchedulingScreen(
                                          vehicleName: _selectedVehicle,
                                          departure: widget.departure,
                                          destination: widget.destination,
                                          departureCoordinates:
                                              widget.departureCoordinates,
                                          destinationCoordinates:
                                              widget.destinationCoordinates,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Brand.accent,
                                    foregroundColor: Brand.bg,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Planifier $_selectedVehicle',
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
