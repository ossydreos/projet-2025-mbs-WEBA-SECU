import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:timezone/timezone.dart' as tz;
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/constants.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

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

class CustomOfferCreationScreen extends StatefulWidget {
  const CustomOfferCreationScreen({super.key});

  @override
  State<CustomOfferCreationScreen> createState() => _CustomOfferCreationScreenState();
}

class _CustomOfferCreationScreenState extends State<CustomOfferCreationScreen> {
  final CustomOfferService _customOfferService = CustomOfferService();
  final _Debouncer _debouncer = _Debouncer(const Duration(milliseconds: 300));
  
  // Contrôleurs de texte
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Variables d'état
  String? _selectedDeparture;
  String? _selectedDestination;
  LatLng? _departureCoordinates;
  LatLng? _destinationCoordinates;
  List<Suggestion> _departureSuggestions = [];
  List<Suggestion> _destinationSuggestions = [];
  bool _isLoadingDeparture = false;
  bool _isLoadingDestination = false;
  bool _isCreatingOffer = false;
  bool _isDepartureActive = false;
  bool _isDestinationActive = false;
  bool _isSelectingSuggestion = false;
  bool _hasTriedToSubmit = false;
  
  // Date et heure
  DateTime _startDate = DateTime.now();
  TimeOfDay? _startTime;
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay? _endTime;
  
  // Focus nodes
  final FocusNode _departureFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();

  // Session token pour Google Places
  final String _placesSessionToken = DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _initializeTime();
    _checkForPendingOffers();
    
    // Écouter les changements de focus
    _departureFocusNode.addListener(() {
      setState(() {
        _isDepartureActive = _departureFocusNode.hasFocus;
        if (_isDepartureActive) {
          _destinationSuggestions = [];
        }
      });
    });
    
    _destinationFocusNode.addListener(() {
      setState(() {
        _isDestinationActive = _destinationFocusNode.hasFocus;
        if (_isDestinationActive) {
          _departureSuggestions = [];
        }
      });
    });

    // Écouter les changements de texte
    _departureController.addListener(_onDepartureTextChanged);
    _destinationController.addListener(_onDestinationTextChanged);
  }

  void _checkForPendingOffers() async {
    try {
      final offers = await _customOfferService.getUserCustomOffers().first;
      final pendingOffers = offers.where((o) => o.status == CustomOfferStatus.pending).toList();
      
      if (pendingOffers.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà une offre en attente. Veuillez attendre la réponse du chauffeur.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Erreur silencieuse, on continue
    }
  }

  void _initializeTime() {
    try {
      // Définir l'heure par défaut à 30 minutes après l'heure actuelle de Zurich
      final zurichTime = tz.TZDateTime.now(tz.getLocation('Europe/Zurich'));
      final defaultStartTime = zurichTime.add(const Duration(minutes: 30));
      final defaultEndTime = zurichTime.add(const Duration(hours: 1, minutes: 30));
      
      _startTime = TimeOfDay(hour: defaultStartTime.hour, minute: defaultStartTime.minute);
      _endTime = TimeOfDay(hour: defaultEndTime.hour, minute: defaultEndTime.minute);
    } catch (e) {
      // Fallback vers l'heure locale si la base de données n'est pas encore initialisée
      final now = DateTime.now();
      final defaultStartTime = now.add(const Duration(minutes: 30));
      final defaultEndTime = now.add(const Duration(hours: 1, minutes: 30));
      
      _startTime = TimeOfDay(hour: defaultStartTime.hour, minute: defaultStartTime.minute);
      _endTime = TimeOfDay(hour: defaultEndTime.hour, minute: defaultEndTime.minute);
    }
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    _departureFocusNode.dispose();
    _destinationFocusNode.dispose();
    _noteFocusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onDepartureTextChanged() {
    if (_isSelectingSuggestion) return; // Ignorer si on est en train de sélectionner une suggestion
    
    final query = _departureController.text;
    if (query.isEmpty) {
      setState(() {
        _departureSuggestions = [];
      });
      return;
    }
    _debouncer(() => _fetchDepartureSuggestionsPlaces(query));
  }

  void _onDestinationTextChanged() {
    if (_isSelectingSuggestion) return; // Ignorer si on est en train de sélectionner une suggestion
    
    final query = _destinationController.text;
    if (query.isEmpty) {
      setState(() {
        _destinationSuggestions = [];
      });
      return;
    }
    _debouncer(() => _fetchDestinationSuggestionsPlaces(query));
  }

  Future<void> _fetchDepartureSuggestionsPlaces(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingDeparture = true;
    });
    
    try {
      final key = (AppConstants.googlePlacesWebKey.isNotEmpty)
          ? AppConstants.googlePlacesWebKey
          : (Platform.isIOS
                ? AppConstants.googleMapsApiKeyIOS
                : AppConstants.googleMapsApiKeyAndroid);
      
      // Obtenir la position actuelle pour le tri par proximité
      String locationParam = '';
      try {
        final position = await Geolocator.getCurrentPosition();
        locationParam = '&location=${position.latitude},${position.longitude}&radius=50000';
      } catch (e) {
        // Si pas de géolocalisation, utiliser Genève par défaut
        locationParam = '&location=46.2044,6.1432&radius=50000';
      }
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&language=fr'
        '&components=country:fr|country:ch'
        '&sessiontoken=$_placesSessionToken'
        '$locationParam'
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
          
          // Utiliser l'ordre de Google Places (trié par proximité)
          
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

  Future<void> _fetchDestinationSuggestionsPlaces(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingDestination = true;
    });
    
    try {
      final key = (AppConstants.googlePlacesWebKey.isNotEmpty)
          ? AppConstants.googlePlacesWebKey
          : (Platform.isIOS
                ? AppConstants.googleMapsApiKeyIOS
                : AppConstants.googleMapsApiKeyAndroid);
      
      // Obtenir la position actuelle pour le tri par proximité
      String locationParam = '';
      try {
        final position = await Geolocator.getCurrentPosition();
        locationParam = '&location=${position.latitude},${position.longitude}&radius=50000';
      } catch (e) {
        // Si pas de géolocalisation, utiliser Genève par défaut
        locationParam = '&location=46.2044,6.1432&radius=50000';
      }
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&language=fr'
        '&components=country:fr|country:ch'
        '&sessiontoken=$_placesSessionToken'
        '$locationParam'
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
          
          // Utiliser l'ordre de Google Places (trié par proximité)
          
          setState(() {
            _destinationSuggestions = suggestions;
            _isLoadingDestination = false;
          });
        } else {
          setState(() {
            _isLoadingDestination = false;
            _destinationSuggestions = [];
          });
        }
      } else {
        setState(() {
          _isLoadingDestination = false;
          _destinationSuggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDestination = false;
        _destinationSuggestions = [];
      });
    }
  }

  Future<LatLng?> _fetchPlaceDetailsLatLng(String placeId) async {
    try {
      final key = (AppConstants.googlePlacesWebKey.isNotEmpty)
          ? AppConstants.googlePlacesWebKey
          : (Platform.isIOS
                ? AppConstants.googleMapsApiKeyIOS
                : AppConstants.googleMapsApiKeyAndroid);
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=$key',
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        if (result != null) {
          final geometry = result['geometry'] as Map<String, dynamic>?;
          if (geometry != null) {
            final location = geometry['location'] as Map<String, dynamic>?;
            if (location != null) {
              return LatLng(
                (location['lat'] as num).toDouble(),
                (location['lng'] as num).toDouble(),
              );
            }
          }
        }
      }
    } catch (e) {
      // Ignorer l'erreur
    }
    return null;
  }

  Future<void> _onSuggestionTap(Suggestion suggestion, bool isDeparture) async {
    // Marquer qu'on est en train de sélectionner une suggestion
    _isSelectingSuggestion = true;
    
    LatLng? coords = suggestion.coordinates;
    if (coords == null && suggestion.placeId != null) {
      coords = await _fetchPlaceDetailsLatLng(suggestion.placeId!);
    }
    
    if (isDeparture) {
      setState(() {
        _departureController.text = suggestion.shortName;
        _departureSuggestions = [];
        _departureCoordinates = coords;
        _selectedDeparture = suggestion.shortName;
      });
    } else {
      setState(() {
        _destinationController.text = suggestion.shortName;
        _destinationSuggestions = [];
        _destinationCoordinates = coords;
        _selectedDestination = suggestion.shortName;
      });
    }
    
    // Fermer le clavier
    FocusScope.of(context).unfocus();
    
    // Réactiver les listeners après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSelectingSuggestion = false;
    });
  }

  bool _isFormValid() {
    // Vérifier que départ et destination sont sélectionnés
    if (_selectedDeparture == null || _selectedDestination == null ||
        _departureCoordinates == null || _destinationCoordinates == null) {
      return false;
    }
    
    // Vérifier que la date/heure de début est dans le futur
    final now = DateTime.now();
      final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime!.hour, _startTime!.minute);
    
    return startDateTime.isAfter(now);
  }

  bool _isDepartureValid() {
    return _selectedDeparture != null && _departureCoordinates != null;
  }

  bool _isDestinationValid() {
    return _selectedDestination != null && _destinationCoordinates != null;
  }

  bool _isDateTimeValid() {
    if (_startTime == null) return false;
    
    try {
      // Utiliser l'heure de Zurich pour la validation
      final zurichTime = tz.TZDateTime.now(tz.getLocation('Europe/Zurich'));
      final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime!.hour, _startTime!.minute);
      return startDateTime.isAfter(zurichTime);
    } catch (e) {
      // Fallback vers l'heure locale
      final now = DateTime.now();
      final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime!.hour, _startTime!.minute);
      return startDateTime.isAfter(now);
    }
  }

  Future<void> _createCustomOffer() async {
    setState(() {
      _hasTriedToSubmit = true;
    });
    
    if (!_isFormValid()) return;

    setState(() {
      _isCreatingOffer = true;
    });

    try {
      // Calculer la durée en heures et minutes
      final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime!.hour, _startTime!.minute);
      final endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime!.hour, _endTime!.minute);
      final duration = endDateTime.difference(startDateTime);
      
      final durationHours = duration.inHours;
      final durationMinutes = duration.inMinutes % 60;

      final offerId = await _customOfferService.createCustomOffer(
        departure: _selectedDeparture!,
        destination: _selectedDestination!,
        durationHours: durationHours,
        durationMinutes: durationMinutes,
        clientNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        departureCoordinates: _departureCoordinates != null
            ? {
                'latitude': _departureCoordinates!.latitude,
                'longitude': _departureCoordinates!.longitude,
              }
            : null,
        destinationCoordinates: _destinationCoordinates != null
            ? {
                'latitude': _destinationCoordinates!.latitude,
                'longitude': _destinationCoordinates!.longitude,
              }
            : null,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );

      if (mounted) {
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorUnknownError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingOffer = false;
        });
      }
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  Widget _buildLocationField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isLoading,
    required List<Suggestion> suggestions,
    required bool isDeparture,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(
              isDeparture ? Icons.location_on : Icons.location_on_outlined,
              color: Colors.white70,
              size: 22,
            ),
            suffixIcon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (_hasTriedToSubmit && (isDeparture ? !_isDepartureValid() : !_isDestinationValid())) 
                    ? Colors.red.withOpacity(0.6) 
                    : Colors.white.withOpacity(0.2)
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (_hasTriedToSubmit && (isDeparture ? !_isDepartureValid() : !_isDestinationValid())) 
                    ? Colors.red.withOpacity(0.6) 
                    : Colors.white.withOpacity(0.2)
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (_hasTriedToSubmit && (isDeparture ? !_isDepartureValid() : !_isDestinationValid())) 
                    ? Colors.red.withOpacity(0.8) 
                    : Colors.white.withOpacity(0.4)
              ),
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: suggestions.take(5).map((suggestion) {
                return ListTile(
                  leading: Icon(suggestion.icon, color: Colors.white70),
                  title: Text(
                    suggestion.shortName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    suggestion.address,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => _onSuggestionTap(suggestion, isDeparture),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeSelector({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_hasTriedToSubmit && !_isDateTimeValid()) 
                          ? Colors.red.withOpacity(0.6) 
                          : Colors.white.withOpacity(0.2)
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onTimeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_hasTriedToSubmit && !_isDateTimeValid()) 
                          ? Colors.red.withOpacity(0.6) 
                          : Colors.white.withOpacity(0.2)
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        time != null 
                          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).noteForDriver,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          focusNode: _noteFocusNode,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).noteForDriverHint,
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).createCustomOffer,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Point de départ
              _buildLocationField(
                label: AppLocalizations.of(context).departure,
                controller: _departureController,
                focusNode: _departureFocusNode,
                isLoading: _isLoadingDeparture,
                suggestions: _departureSuggestions,
                isDeparture: true,
              ),

              const SizedBox(height: 24),

              // Point de destination
              _buildLocationField(
                label: AppLocalizations.of(context).destination,
                controller: _destinationController,
                focusNode: _destinationFocusNode,
                isLoading: _isLoadingDestination,
                suggestions: _destinationSuggestions,
                isDeparture: false,
              ),

              const SizedBox(height: 24),

              // Date et heure de début
              _buildDateTimeSelector(
                label: 'Date et heure de début',
                date: _startDate,
                time: _startTime ?? TimeOfDay.now(),
                onDateTap: _selectStartDate,
                onTimeTap: _selectStartTime,
              ),

              const SizedBox(height: 24),

              // Date et heure de fin
              _buildDateTimeSelector(
                label: 'Date et heure de fin',
                date: _endDate,
                time: _endTime ?? TimeOfDay.now(),
                onDateTap: _selectEndDate,
                onTimeTap: _selectEndTime,
              ),

              const SizedBox(height: 24),

              // Champ de note
              _buildNoteField(),

              const SizedBox(height: 32),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid() && !_isCreatingOffer
                      ? _createCustomOffer
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid() && !_isCreatingOffer
                        ? AppColors.accent
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreatingOffer
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).createOffer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}