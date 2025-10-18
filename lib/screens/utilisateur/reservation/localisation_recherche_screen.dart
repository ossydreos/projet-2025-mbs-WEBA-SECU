import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/constants.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/booking_screen.dart';
import 'package:my_mobility_services/data/models/favorite_trip.dart' as db_models;
import 'package:my_mobility_services/data/services/favorite_trip_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

class FavoriteTrip {
  final String departure;
  final String destination;
  final String departureAddress;
  final String destinationAddress;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;
  final IconData icon;
  final String name;

  FavoriteTrip({
    required this.departure,
    required this.destination,
    required this.departureAddress,
    required this.destinationAddress,
    this.departureCoordinates,
    this.destinationCoordinates,
    this.icon = Icons.favorite,
    required this.name,
  });
}

class Suggestion {
  final String displayName;
  final String shortName;
  final String address;
  final LatLng? coordinates;
  final IconData icon;
  final String distance;
  final String? placeId;

  Suggestion({
    required this.displayName,
    required this.shortName,
    required this.address,
    required this.coordinates,
    required this.icon,
    required this.distance,
    this.placeId,
  });


  // Google Places prediction → Suggestion (sans coordonnées, récupérées via Place Details)
  factory Suggestion.fromPlaces(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    final shortName = (structured['main_text'] ?? '').toString();
    final secondary = (structured['secondary_text'] ?? '').toString();
    final display = json['description']?.toString() ?? shortName;
    final placeId = json['place_id']?.toString();

    return Suggestion(
      displayName: display,
      shortName: shortName.isNotEmpty ? shortName : display,
      address: secondary,
      coordinates: null,
      icon: Icons.location_on,
      distance: '',
      placeId: placeId,
    );
  }

}

class _Debouncer {
  final Duration delay;
  Timer? _timer;

  _Debouncer(this.delay);

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class LocationSearchScreen extends StatefulWidget {
  final String? currentDestination;
  final String? initialDeparture;
  final String? initialDestination;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;
  final bool fromSummary;

  const LocationSearchScreen({
    super.key, 
    this.currentDestination,
    this.initialDeparture,
    this.initialDestination,
    this.departureCoordinates,
    this.destinationCoordinates,
    this.fromSummary = false,
  });

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _debouncer = _Debouncer(const Duration(milliseconds: 300));
  final String _placesSessionToken = DateTime.now().microsecondsSinceEpoch
      .toString();

  List<Suggestion> _suggestions = [];
  List<Suggestion> _departureSuggestions = [];
  bool _isLoading = false;
  bool _isLoadingDeparture = false;
  String _currentPickupLocation = "Ma position actuelle";
  String? _placesErrorMessage;
  final TextEditingController _departureController = TextEditingController();
  final FocusNode _departureFocusNode = FocusNode();
  bool _isDestinationActive = false;
  bool _isDepartureActive = false;
  LatLng? _currentPositionLatLng;
  String? _currentPositionAddress;
  LatLng? _selectedDepartureCoordinates;
  LatLng? _selectedDestinationCoordinates;

  // Service pour récupérer les trajets favoris depuis la BDD
  final FavoriteTripService _favoriteTripService = FavoriteTripService();
  List<FavoriteTrip> _favoriteTrips = [];

  @override
  void initState() {
    super.initState();

    // Si on a déjà une destination, l'afficher
    if (widget.currentDestination != null) {
      _searchController.text = widget.currentDestination!;
    }
    
    // Pré-remplir les champs avec les valeurs initiales si fournies
    if (widget.initialDeparture != null) {
      _departureController.text = widget.initialDeparture!;
      _currentPickupLocation = widget.initialDeparture!;
    }
    if (widget.initialDestination != null) {
      _searchController.text = widget.initialDestination!;
    }
    
    // Initialiser les coordonnées sélectionnées
    if (widget.departureCoordinates != null) {
      _selectedDepartureCoordinates = widget.departureCoordinates;
    }
    if (widget.destinationCoordinates != null) {
      _selectedDestinationCoordinates = widget.destinationCoordinates;
    }

    // PAS de focus automatique - on veut afficher les favoris par défaut
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _focusNode.requestFocus();
    // });

    // Écouter les changements de texte
    _searchController.addListener(_onTextChanged);
    _departureController.addListener(_onDepartureTextChanged);

    // Écouter les changements de focus
    _focusNode.addListener(() {
      setState(() {
        _isDestinationActive = _focusNode.hasFocus;
        // Si on clique sur un champ, vider les suggestions de l'autre
        if (_isDestinationActive) {
          _departureSuggestions = [];
        }
      });
    });
    _departureFocusNode.addListener(() {
      setState(() {
        _isDepartureActive = _departureFocusNode.hasFocus;
        // Si on clique sur un champ, vider les suggestions de l'autre
        if (_isDepartureActive) {
          _suggestions = [];
        }
      });
    });

    // Initialiser la position actuelle comme valeur par défaut du départ
    _initCurrentLocation();
    
    // Charger les trajets favoris depuis la BDD
    _loadFavoriteTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _departureController.dispose();
    // _focusNode.removeListener(_onDestinationFocusChanged);
    // _departureFocusNode.removeListener(_onDepartureFocusChanged);
    _focusNode.dispose();
    _departureFocusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debouncer(() => _fetchSuggestionsPlaces(query));
  }

  Future<void> _fetchSuggestionsPlaces(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _placesErrorMessage = null;
    });
    try {
      // Utiliser une clé Web (Places Web Service) non restreinte à un bundle/androidId pour les appels REST
      final webKey = await AppConstants.googlePlacesWebKey;
      final key = (webKey.isNotEmpty)
                ? webKey
          : (Platform.isIOS
                ? await AppConstants.googleMapsApiKeyIOS
                : await AppConstants.googleMapsApiKeyAndroid);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&language=fr'
        '&components=country:fr|country:ch'
        '&sessiontoken=$_placesSessionToken'
        '&key=$key',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString();
        if (status == 'OK') {
          final preds = (data['predictions'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          final suggestions = preds
              .map((p) => Suggestion.fromPlaces(p))
              .toList();
          
          // Trier les suggestions : Suisse en premier, puis France, puis autres
          suggestions.sort((a, b) {
            final aIsSwiss = a.address.toLowerCase().contains('suisse') || 
                            a.address.toLowerCase().contains('switzerland') ||
                            a.address.toLowerCase().contains('genève') ||
                            a.address.toLowerCase().contains('zurich') ||
                            a.address.toLowerCase().contains('bern') ||
                            a.address.toLowerCase().contains('lausanne') ||
                            a.address.toLowerCase().contains('basel') ||
                            a.address.toLowerCase().contains('lucerne');
            
            final bIsSwiss = b.address.toLowerCase().contains('suisse') || 
                            b.address.toLowerCase().contains('switzerland') ||
                            b.address.toLowerCase().contains('genève') ||
                            b.address.toLowerCase().contains('zurich') ||
                            b.address.toLowerCase().contains('bern') ||
                            b.address.toLowerCase().contains('lausanne') ||
                            b.address.toLowerCase().contains('basel') ||
                            b.address.toLowerCase().contains('lucerne');
            
            final aIsFrench = a.address.toLowerCase().contains('france') ||
                             a.address.toLowerCase().contains('paris') ||
                             a.address.toLowerCase().contains('lyon') ||
                             a.address.toLowerCase().contains('marseille') ||
                             a.address.toLowerCase().contains('toulouse') ||
                             a.address.toLowerCase().contains('nice');
            
            final bIsFrench = b.address.toLowerCase().contains('france') ||
                             b.address.toLowerCase().contains('paris') ||
                             b.address.toLowerCase().contains('lyon') ||
                             b.address.toLowerCase().contains('marseille') ||
                             b.address.toLowerCase().contains('toulouse') ||
                             b.address.toLowerCase().contains('nice');
            
            // Priorité : Suisse > France > Autres
            if (aIsSwiss && !bIsSwiss) return -1;
            if (!aIsSwiss && bIsSwiss) return 1;
            if (aIsFrench && !bIsFrench && !bIsSwiss) return -1;
            if (!aIsFrench && bIsFrench && !aIsSwiss) return 1;
            
            return 0; // Garder l'ordre original si même priorité
          });
          
          setState(() {
            _suggestions = suggestions;
            _isLoading = false;
          });
        } else {
          final err = (data['error_message'] ?? status).toString();
          debugPrint('Places Autocomplete error: $status - $err');
          setState(() {
            _isLoading = false;
            _suggestions = [];
            _placesErrorMessage = err;
          });
        }
      } else {
        debugPrint(
          'Places Autocomplete HTTP ${response.statusCode}: ${response.body}',
        );
        setState(() {
          _isLoading = false;
          _suggestions = [];
          _placesErrorMessage = 'Erreur réseau (${response.statusCode})';
        });
      }
    } catch (e) {
      debugPrint('Places Autocomplete exception: $e');
      setState(() {
        _isLoading = false;
        _suggestions = [];
        _placesErrorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _onSuggestionTap(Suggestion suggestion) async {
    LatLng? coords = suggestion.coordinates;
    if (coords == null && suggestion.placeId != null) {
      coords = await _fetchPlaceDetailsLatLng(suggestion.placeId!);
    }
    if (_isDestinationActive) {
      setState(() {
        _searchController.text = suggestion.shortName;
        _suggestions = [];
        _selectedDestinationCoordinates = coords; // Stocker les coordonnées de destination
      });
    } else if (_isDepartureActive) {
      setState(() {
        _currentPickupLocation = suggestion.shortName;
        _departureController.clear();
        _departureSuggestions = [];
        _selectedDepartureCoordinates = coords;
      });
    } else {
      // Par défaut, cible la destination
      setState(() {
        _searchController.text = suggestion.shortName;
        _suggestions = [];
      });
    }
    // Fermer le clavier pour éviter les confusions
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
    });
  }

  void _onDepartureTextChanged() {
    final query = _departureController.text;
    if (query.isEmpty) {
      setState(() {
        _departureSuggestions = [];
      });
      return;
    }

    _debouncer(() => _fetchDepartureSuggestionsPlaces(query));
  }

  Future<void> _fetchDepartureSuggestionsPlaces(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingDeparture = true;
    });
    try {
      final webKey = await AppConstants.googlePlacesWebKey;
      final key = (webKey.isNotEmpty)
                ? webKey
          : (Platform.isIOS
                ? await AppConstants.googleMapsApiKeyIOS
                : await AppConstants.googleMapsApiKeyAndroid);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&language=fr'
        '&components=country:fr|country:ch'
        '&sessiontoken=$_placesSessionToken'
        '&key=$key',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if ((data['status'] ?? '') == 'OK') {
          final preds = (data['predictions'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          final suggestions = preds
              .map((p) => Suggestion.fromPlaces(p))
              .toList();
          
          // Trier les suggestions : Suisse en premier, puis France, puis autres
          suggestions.sort((a, b) {
            final aIsSwiss = a.address.toLowerCase().contains('suisse') || 
                            a.address.toLowerCase().contains('switzerland') ||
                            a.address.toLowerCase().contains('genève') ||
                            a.address.toLowerCase().contains('zurich') ||
                            a.address.toLowerCase().contains('bern') ||
                            a.address.toLowerCase().contains('lausanne') ||
                            a.address.toLowerCase().contains('basel') ||
                            a.address.toLowerCase().contains('lucerne');
            
            final bIsSwiss = b.address.toLowerCase().contains('suisse') || 
                            b.address.toLowerCase().contains('switzerland') ||
                            b.address.toLowerCase().contains('genève') ||
                            b.address.toLowerCase().contains('zurich') ||
                            b.address.toLowerCase().contains('bern') ||
                            b.address.toLowerCase().contains('lausanne') ||
                            b.address.toLowerCase().contains('basel') ||
                            b.address.toLowerCase().contains('lucerne');
            
            final aIsFrench = a.address.toLowerCase().contains('france') ||
                             a.address.toLowerCase().contains('paris') ||
                             a.address.toLowerCase().contains('lyon') ||
                             a.address.toLowerCase().contains('marseille') ||
                             a.address.toLowerCase().contains('toulouse') ||
                             a.address.toLowerCase().contains('nice');
            
            final bIsFrench = b.address.toLowerCase().contains('france') ||
                             b.address.toLowerCase().contains('paris') ||
                             b.address.toLowerCase().contains('lyon') ||
                             b.address.toLowerCase().contains('marseille') ||
                             b.address.toLowerCase().contains('toulouse') ||
                             b.address.toLowerCase().contains('nice');
            
            // Priorité : Suisse > France > Autres
            if (aIsSwiss && !bIsSwiss) return -1;
            if (!aIsSwiss && bIsSwiss) return 1;
            if (aIsFrench && !bIsFrench && !bIsSwiss) return -1;
            if (!aIsFrench && bIsFrench && !aIsSwiss) return 1;
            
            return 0; // Garder l'ordre original si même priorité
          });
          
          setState(() {
            _departureSuggestions = suggestions;
            _isLoadingDeparture = false;
          });
        } else {
          setState(() {
            _isLoadingDeparture = false;
            _departureSuggestions = [];
          });
        }
      } else {
        setState(() {
          _isLoadingDeparture = false;
          _departureSuggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDeparture = false;
        _departureSuggestions = [];
      });
    }
  }

  Future<void> _onDepartureSuggestionTap(Suggestion suggestion) async {
    LatLng? coords = suggestion.coordinates;
    if (coords == null && suggestion.placeId != null) {
      coords = await _fetchPlaceDetailsLatLng(suggestion.placeId!);
    }
    setState(() {
      _currentPickupLocation = suggestion.shortName;
      _departureController.clear();
      _departureSuggestions = [];
      _selectedDepartureCoordinates = coords;
    });
  }

  void _clearDepartureSearch() {
    _departureController.clear();
    setState(() {
      _departureSuggestions = [];
    });
  }

  void _onDestinationFocusChanged() {
    // Si on perd le focus sur la destination, nettoyer les suggestions
    if (!_focusNode.hasFocus) {
      setState(() {
        _suggestions = [];
      });
    }
  }

  void _onDepartureFocusChanged() {
    // Si on perd le focus sur le départ, nettoyer les suggestions
    if (!_departureFocusNode.hasFocus) {
      setState(() {
        _departureSuggestions = [];
      });
    }
  }

  Future<void> _initCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentPositionLatLng = null;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          setState(() {
            _currentPositionLatLng = null;
          });
          return;
        }
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _currentPositionLatLng = null;
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        setState(() {
          _currentPositionLatLng = null;
        });
        return;
      }
      final currentLatLng = LatLng(position.latitude, position.longitude);

      String? addressLine;
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = p.street?.trim();
          final postal = p.postalCode?.trim();
          final city = p.locality?.trim();
          final parts = [street, postal, city]
              .where((s) => s != null && s!.isNotEmpty)
              .cast<String>()
              .toList();
          addressLine = parts.join(' ');
        }
      } catch (_) {}

      setState(() {
        _currentPositionLatLng = currentLatLng;
        _currentPositionAddress = addressLine;
        // _currentPickupLocation reste "Ma position actuelle"
      });
    } catch (e) {
      setState(() {
        _currentPositionLatLng = null;
      });
    }
  }

  bool _canProceed() {
    return _searchController.text.isNotEmpty;
  }

  Future<void> _proceedToBooking() async {
    // Retourner les données à l'écran principal avec les deux adresses
    final String departureLabel =
        (_currentPickupLocation == 'Ma position actuelle' &&
                (_currentPositionAddress != null &&
                    _currentPositionAddress!.isNotEmpty))
            ? _currentPositionAddress!
            : _currentPickupLocation;
    
    // Si pas de coordonnées de destination sélectionnées, essayer de les récupérer via géocoding
    LatLng? destinationCoords = _selectedDestinationCoordinates;
    if (destinationCoords == null && _searchController.text.isNotEmpty) {
      destinationCoords = await _geocodeAddress(_searchController.text);
    }
    
    if (widget.fromSummary) {
      // Si on vient du résumé, aller vers BookingScreen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            departure: departureLabel,
            destination: _searchController.text,
            departureCoordinates: _selectedDepartureCoordinates ?? _currentPositionLatLng,
            destinationCoordinates: destinationCoords,
            fromSummary: true,
          ),
        ),
      );
      
      // Retourner le résultat de BookingScreen à TripSummaryScreen
      Navigator.pop(context, result);
    } else {
      // Comportement normal : retourner les données à l'écran principal
      Navigator.pop(context, {
        'departure': departureLabel,
        'destination': _searchController.text,
        'departureCoordinates': _selectedDepartureCoordinates ?? _currentPositionLatLng,
        'destinationCoordinates': destinationCoords,
      });
    }
  }

  // Géocoder une adresse pour récupérer ses coordonnées
  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final webKey = await AppConstants.googlePlacesWebKey;
      final key = (webKey.isNotEmpty)
                ? webKey
          : (Platform.isIOS
                ? await AppConstants.googleMapsApiKeyIOS
                : await AppConstants.googleMapsApiKeyAndroid);
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$key',
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          return LatLng(
            location['lat'].toDouble(),
            location['lng'].toDouble(),
          );
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
    return null;
  }

  Future<LatLng?> _fetchPlaceDetailsLatLng(String placeId) async {
    try {
      final webKey = await AppConstants.googlePlacesWebKey;
      final key = (webKey.isNotEmpty)
                ? webKey
          : (Platform.isIOS
                ? await AppConstants.googleMapsApiKeyIOS
                : await AppConstants.googleMapsApiKeyAndroid);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$key',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final loc = data['result']?['geometry']?['location'];
        if (loc != null) {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          return LatLng(lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  // Charger les trajets favoris depuis la BDD
  Future<void> _loadFavoriteTrips() async {
    try {
      final dbTrips = await _favoriteTripService.getFavoriteTrips().first;
      setState(() {
        _favoriteTrips = dbTrips.map((dbTrip) => FavoriteTrip(
          departure: dbTrip.departureAddress,
          destination: dbTrip.arrivalAddress,
          departureAddress: dbTrip.departureAddress,
          destinationAddress: dbTrip.arrivalAddress,
          departureCoordinates: dbTrip.departureCoordinates,
          destinationCoordinates: dbTrip.arrivalCoordinates,
          icon: dbTrip.icon,
          name: dbTrip.name,
        )).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des trajets favoris: $e');
      // En cas d'erreur, garder la liste vide
      setState(() {
        _favoriteTrips = [];
      });
    }
  }

  // Méthode pour gérer le clic sur un trajet favori
  void _onFavoriteTripTap(FavoriteTrip favoriteTrip) {
    setState(() {
      // Remplir le champ de départ
      _currentPickupLocation = favoriteTrip.departure;
      _departureController.text = favoriteTrip.departure;
      _selectedDepartureCoordinates = favoriteTrip.departureCoordinates;
      
      // Remplir le champ de destination
      _searchController.text = favoriteTrip.destination;
      _selectedDestinationCoordinates = favoriteTrip.destinationCoordinates;
      
      // Vider les suggestions
      _suggestions = [];
      _departureSuggestions = [];
    });
    
    // Fermer le clavier
    FocusScope.of(context).unfocus();
  }

  // Widget pour afficher les trajets favoris
  Widget _buildFavoriteTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _favoriteTrips.length,
      itemBuilder: (context, index) {
        final favoriteTrip = _favoriteTrips[index];
        return GlassContainer(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: InkWell(
            onTap: () => _onFavoriteTripTap(favoriteTrip),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // Icône du trajet favori
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    favoriteTrip.icon,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Informations du trajet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du trajet
                      Text(
                        favoriteTrip.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Départ
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              favoriteTrip.departure,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Destination
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              favoriteTrip.destination,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Flèche
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.text,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    // Si aucun champ n'a le focus, afficher les trajets favoris
    if (!_isDepartureActive && !_isDestinationActive) {
      return Column(
        children: [
          // Titre des trajets favoris
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trajets favoris',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Liste des trajets favoris
          Expanded(child: _buildFavoriteTripsList()),
        ],
      );
    }

    // Afficher les suggestions selon le champ actuellement FOCUS
    if (_isDepartureActive) {
      if (_isLoadingDeparture) {
        return Center(child: CircularProgressIndicator(color: AppColors.accent));
      }

      // Construire la liste avec "Ma position actuelle" en tête si disponible
      final List<Suggestion> items = [];
      if (_currentPositionLatLng != null) {
        items.add(
          Suggestion(
            displayName: 'Ma position actuelle',
            shortName: 'Ma position actuelle',
            address: _currentPositionAddress ?? '',
            coordinates: _currentPositionLatLng,
            icon: Icons.my_location,
            distance: '',
          ),
        );
      }
      items.addAll(_departureSuggestions);

      if (items.isEmpty) {
        return Center(
          child: Text(
            'Aucun résultat trouvé',
            style: TextStyle(color: AppColors.text, fontSize: 16),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final suggestion = items[index];
          return GlassContainer(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(suggestion.icon, color: AppColors.accent, size: 24),
              title: Text(
                suggestion.shortName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              subtitle: suggestion.address.isNotEmpty
                  ? Text(
                      suggestion.address,
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: suggestion.distance.isNotEmpty
                  ? Text(
                      suggestion.distance,
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                    )
                  : null,
              onTap: () => _onSuggestionTap(suggestion),
            ),
          );
        },
      );
    }

    // Suggestions destination si le champ destination est en focus
    if (_isDestinationActive) {
      if (_isLoading) {
        return Center(child: CircularProgressIndicator(color: AppColors.accent));
      }

      if (_suggestions.isEmpty) {
        return Center(
          child: Text(
            'Aucun résultat trouvé',
            style: TextStyle(color: AppColors.text, fontSize: 16),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return GlassContainer(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(suggestion.icon, color: AppColors.accent, size: 24),
              title: Text(
                suggestion.shortName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              subtitle: suggestion.address.isNotEmpty
                  ? Text(
                      suggestion.address,
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Text(
                suggestion.distance,
                style: TextStyle(fontSize: 14, color: AppColors.text),
              ),
              onTap: () => _onSuggestionTap(suggestion),
            ),
          );
        },
      );
    }

    // Si aucun champ n'a le focus, message d'erreur API éventuel
    if (_placesErrorMessage != null) {
      return Center(
        child: Text(
          _placesErrorMessage!,
          style: TextStyle(color: AppColors.text, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Header avec boutons et titre - THÉMATISÉ
            GlassContainer(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                children: [
                  // Barre de titre - THÉMATISÉE
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 32, color: Colors.white),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Votre itinéraire',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white, // ✅ Texte blanc
                            ),
                          ),
                        ),
                      ),
                      Icon(Icons.sort, size: 24, color: AppColors.text),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Point de départ (cliquable) - THÉMATISÉ (sans double contour)
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    showBorder: false,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _departureController,
                            focusNode: _departureFocusNode,
                            onChanged: (value) => _onDepartureTextChanged(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white, // ✅ Texte blanc
                            ),
                            decoration: InputDecoration(
                              hintText: _currentPickupLocation,
                              hintStyle: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                              ),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (_departureController.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearDepartureSearch,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Icon(
                                Icons.clear,
                                color: AppColors.text,
                                size: 20,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.add, color: AppColors.text, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Zone de recherche destination - THÉMATISÉE (sans double contour)
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    showBorder: false,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.search,
                            color: AppColors.text,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white, // ✅ Texte blanc
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).destination,
                              hintStyle: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                              ),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearSearch,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Icon(
                                Icons.clear,
                                color: AppColors.text,
                                size: 20,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.location_on,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Liste des suggestions - THÉMATISÉE
            Expanded(child: _buildSuggestionsList()),

            // Footer avec bouton suivant - THÉMATISÉ
            GlassContainer(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton suivant
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        label: 'Continuer',
                        onPressed: _canProceed() ? _proceedToBooking : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'powered by OpenStreetMap',
                      style: TextStyle(
                        color: AppColors.text.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
