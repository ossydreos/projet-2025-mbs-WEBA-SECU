import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/constants.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';
import 'package:my_mobility_services/data/services/vehicle_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/widgets/ios_time_picker.dart';

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
  State<CustomOfferCreationScreen> createState() =>
      _CustomOfferCreationScreenState();
}

class _CustomOfferCreationScreenState extends State<CustomOfferCreationScreen> {
  final CustomOfferService _customOfferService = CustomOfferService();
  final _Debouncer _debouncer = _Debouncer(const Duration(milliseconds: 500));
  final VehicleService _vehicleService = VehicleService();

  // Couleur par catégorie (aligné sur BookingScreen)
  Color _getVehicleColor(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.economique:
        return AppColors.accent;
      case VehicleCategory.van:
        return AppColors.accent2;
      case VehicleCategory.luxe:
        return AppColors.hot;
    }
  }

  // Cache pour éviter les appels répétés
  Position? _cachedPosition;
  DateTime? _lastPositionFetch;

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
  
  // Sélection de véhicule
  VehiculeType? _selectedVehicle;

  // Focus nodes
  final FocusNode _departureFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();

  // Session token pour Google Places
  final String _placesSessionToken = DateTime.now().microsecondsSinceEpoch
      .toString();

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
      final pendingOffers = offers
          .where((o) => o.status == ReservationStatus.pending)
          .toList();

      if (pendingOffers.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vous avez déjà une offre en attente. Veuillez attendre la réponse du chauffeur.',
            ),
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
      final defaultEndTime = zurichTime.add(
        const Duration(hours: 1, minutes: 30),
      );

      _startTime = TimeOfDay(
        hour: defaultStartTime.hour,
        minute: defaultStartTime.minute,
      );
      _endTime = TimeOfDay(
        hour: defaultEndTime.hour,
        minute: defaultEndTime.minute,
      );
    } catch (e) {
      // Fallback vers l'heure locale si la base de données n'est pas encore initialisée
      final now = DateTime.now();
      final defaultStartTime = now.add(const Duration(minutes: 30));
      final defaultEndTime = now.add(const Duration(hours: 1, minutes: 30));

      _startTime = TimeOfDay(
        hour: defaultStartTime.hour,
        minute: defaultStartTime.minute,
      );
      _endTime = TimeOfDay(
        hour: defaultEndTime.hour,
        minute: defaultEndTime.minute,
      );
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
    if (_isSelectingSuggestion)
      return; // Ignorer si on est en train de sélectionner une suggestion

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
    if (_isSelectingSuggestion)
      return; // Ignorer si on est en train de sélectionner une suggestion

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

      // Utiliser la position cachée ou Genève par défaut (plus rapide)
      String locationParam = '';
      if (_cachedPosition != null &&
          _lastPositionFetch != null &&
          DateTime.now().difference(_lastPositionFetch!).inMinutes < 5) {
        // Utiliser la position cachée si elle est récente (< 5 min)
        locationParam =
            '&location=${_cachedPosition!.latitude},${_cachedPosition!.longitude}&radius=50000';
      } else {
        // Sinon utiliser Genève par défaut (plus rapide que géolocalisation)
        locationParam = '&location=46.2044,6.1432&radius=50000';

        // Récupérer la position en arrière-plan pour le prochain appel
        _updatePositionInBackground();
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&language=fr'
        '&components=country:ch|country:fr' // Suisse en premier
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

          // Tri rapide côté client : Suisse en premier
          suggestions.sort((a, b) {
            final aIsSwiss =
                a.address.toLowerCase().contains('suisse') ||
                a.address.toLowerCase().contains('switzerland') ||
                a.address.toLowerCase().contains('genève') ||
                a.address.toLowerCase().contains('zurich') ||
                a.address.toLowerCase().contains('bern') ||
                a.address.toLowerCase().contains('lausanne');

            final bIsSwiss =
                b.address.toLowerCase().contains('suisse') ||
                b.address.toLowerCase().contains('switzerland') ||
                b.address.toLowerCase().contains('genève') ||
                b.address.toLowerCase().contains('zurich') ||
                b.address.toLowerCase().contains('bern') ||
                b.address.toLowerCase().contains('lausanne');

            if (aIsSwiss && !bIsSwiss) return -1;
            if (!aIsSwiss && bIsSwiss) return 1;
            return 0;
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

      // Utiliser la position cachée ou Genève par défaut (plus rapide)
      String locationParam = '';
      if (_cachedPosition != null &&
          _lastPositionFetch != null &&
          DateTime.now().difference(_lastPositionFetch!).inMinutes < 5) {
        // Utiliser la position cachée si elle est récente (< 5 min)
        locationParam =
            '&location=${_cachedPosition!.latitude},${_cachedPosition!.longitude}&radius=50000';
      } else {
        // Sinon utiliser Genève par défaut (plus rapide que géolocalisation)
        locationParam = '&location=46.2044,6.1432&radius=50000';

        // Récupérer la position en arrière-plan pour le prochain appel
        _updatePositionInBackground();
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&language=fr'
        '&components=country:ch|country:fr' // Suisse en premier
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

          // Tri rapide côté client : Suisse en premier
          suggestions.sort((a, b) {
            final aIsSwiss =
                a.address.toLowerCase().contains('suisse') ||
                a.address.toLowerCase().contains('switzerland') ||
                a.address.toLowerCase().contains('genève') ||
                a.address.toLowerCase().contains('zurich') ||
                a.address.toLowerCase().contains('bern') ||
                a.address.toLowerCase().contains('lausanne');

            final bIsSwiss =
                b.address.toLowerCase().contains('suisse') ||
                b.address.toLowerCase().contains('switzerland') ||
                b.address.toLowerCase().contains('genève') ||
                b.address.toLowerCase().contains('zurich') ||
                b.address.toLowerCase().contains('bern') ||
                b.address.toLowerCase().contains('lausanne');

            if (aIsSwiss && !bIsSwiss) return -1;
            if (!aIsSwiss && bIsSwiss) return 1;
            return 0;
          });

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

  // Méthode pour mettre à jour la position en arrière-plan (non bloquante)
  void _updatePositionInBackground() {
    Future.delayed(Duration.zero, () async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3), // Timeout rapide
        );
        _cachedPosition = position;
        _lastPositionFetch = DateTime.now();
      } catch (e) {
        // Ignorer les erreurs de géolocalisation
        print('Géolocalisation en arrière-plan échouée: $e');
      }
    });
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
    if (_selectedDeparture == null ||
        _selectedDestination == null ||
        _departureCoordinates == null ||
        _destinationCoordinates == null) {
      return false;
    }

    // Vérifier que la date/heure de début est dans le futur
    final now = DateTime.now();
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime!.hour,
      _startTime!.minute,
    );

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
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      // Ajouter 30 minutes de marge pour la préparation
      final minimumDateTime = zurichTime.add(const Duration(minutes: 30));
      return startDateTime.isAfter(minimumDateTime);
    } catch (e) {
      // Fallback vers l'heure locale
      final now = DateTime.now();
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      // Ajouter 30 minutes de marge pour la préparation
      final minimumDateTime = now.add(const Duration(minutes: 30));
      return startDateTime.isAfter(minimumDateTime);
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
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime!.hour,
        _endTime!.minute,
      );
      final duration = endDateTime.difference(startDateTime);

      final durationHours = duration.inHours;
      final durationMinutes = duration.inMinutes % 60;

      await _customOfferService.createCustomOffer(
        departure: _selectedDeparture!,
        destination: _selectedDestination!,
        durationHours: durationHours,
        durationMinutes: durationMinutes,
        vehicleId: _selectedVehicle?.id,
        vehicleName: _selectedVehicle?.name,
        clientNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).errorUnknownError}: $e',
            ),
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
    TimeOfDay? time;

    // Utiliser la roulette iOS sur iOS, picker Android standard sur Android
    if (Platform.isIOS) {
      time = await showIOSTimePicker(
        context: context,
        initialTime: _startTime ?? TimeOfDay.now(),
        title: 'Heure de début',
        subtitle: 'Sélectionnez l\'heure de début de votre offre',
      );
    } else {
      time = await showTimePicker(
        context: context,
        initialTime: _startTime ?? TimeOfDay.now(),
      );
    }

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
    TimeOfDay? time;

    // Utiliser la roulette iOS sur iOS, picker Android standard sur Android
    if (Platform.isIOS) {
      time = await showIOSTimePicker(
        context: context,
        initialTime: _endTime ?? TimeOfDay.now(),
        title: 'Heure de fin',
        subtitle: 'Sélectionnez l\'heure de fin de votre offre',
      );
    } else {
      time = await showTimePicker(
        context: context,
        initialTime: _endTime ?? TimeOfDay.now(),
      );
    }

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
    final hasError = _hasTriedToSubmit && (isDeparture ? !_isDepartureValid() : !_isDestinationValid());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: label),
        const SizedBox(height: 12),
        _GlassInputField(
          controller: controller,
          focusNode: focusNode,
          hintText: label,
          prefixIcon: isDeparture ? Icons.location_on : Icons.location_on_outlined,
          isLoading: isLoading,
          hasError: hasError,
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          const _FieldCaption(text: 'Sélectionnez une adresse valide'),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SuggestionsPanel(
            suggestions: suggestions.take(5).toList(),
            onSuggestionTap: (suggestion) => _onSuggestionTap(suggestion, isDeparture),
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
    final hasError = _hasTriedToSubmit && !_isDateTimeValid();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: label),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassDateTimeField(
                icon: Icons.calendar_today,
                text: '${date.day}/${date.month}/${date.year}',
                onTap: onDateTap,
                hasError: hasError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassDateTimeField(
                icon: Icons.access_time,
                text: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                onTap: onTimeTap,
                hasError: hasError,
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          const _FieldCaption(text: 'La date/heure doit être ≥ 30 min'),
        ],
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: AppLocalizations.of(context).noteForDriver),
        const SizedBox(height: 12),
        _GlassInputField(
          controller: _noteController,
          focusNode: _noteFocusNode,
          hintText: AppLocalizations.of(context).noteForDriverHint,
          maxLines: 4,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).viewPadding;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).createCustomOffer,
        ),
        body: Stack(
          children: [
            const _HeaderGlow(),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + math.max(16, viewPadding.bottom) + (viewInsets.bottom > 0 ? viewInsets.bottom : 0),
              ),
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

                  const SizedBox(height: 20),

                  // Date et heure de début
                  _buildDateTimeSelector(
                    label: 'Date et heure de début',
                    date: _startDate,
                    time: _startTime ?? TimeOfDay.now(),
                    onDateTap: _selectStartDate,
                    onTimeTap: _selectStartTime,
                  ),

                  const SizedBox(height: 20),

                  // Date et heure de fin
                  _buildDateTimeSelector(
                    label: 'Date et heure de fin',
                    date: _endDate,
                    time: _endTime ?? TimeOfDay.now(),
                    onDateTap: _selectEndDate,
                    onTimeTap: _selectEndTime,
                  ),

                  const SizedBox(height: 20),

                  // Sélecteur de véhicule (liste en temps réel)
                  _SectionLabel(text: 'Véhicule'),
                  const SizedBox(height: 12),
                  _GlassVehicleSelector(
                    selectedVehicle: _selectedVehicle,
                    onVehicleSelected: (vehicle) {
                      setState(() {
                        _selectedVehicle = vehicle;
                      });
                    },
                    vehicleService: _vehicleService,
                    getVehicleColor: _getVehicleColor,
                  ),

                  // Champ de note
                  const SizedBox(height: 20),
                  _buildNoteField(),

                  // Espace pour respirer au-dessus de la barre CTA collante
                  SizedBox(height: math.max(16, viewPadding.bottom)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: (viewInsets.bottom > 0)
                ? (viewInsets.bottom + 20)
                : math.max(20, viewPadding.bottom + 8),
            top: 10,
          ),
          child: _GlassCreateButton(
            onPressed: _isFormValid() && !_isCreatingOffer && _selectedVehicle != null
                ? _createCustomOffer
                : null,
            isLoading: _isCreatingOffer,
            text: AppLocalizations.of(context).createOffer,
          ),
        ),
      ),
    );
  }
}

// ======================
// SUB-WIDGETS (PRIVATE)
// ======================

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textStrong,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData? prefixIcon;
  final bool isLoading;
  final bool hasError;
  final int? maxLines;

  const _GlassInputField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.prefixIcon,
    this.isLoading = false,
    this.hasError = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(color: AppColors.text),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.textWeak),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textWeak, size: 20)
                : null,
            suffixIcon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? AppColors.hot : Colors.transparent,
                width: hasError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? AppColors.hot : Colors.transparent,
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? AppColors.hot : AppColors.accent,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _GlassDateTimeField extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool hasError;

  const _GlassDateTimeField({
    required this.icon,
    required this.text,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _PressableScale(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textWeak, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: hasError ? AppColors.hot : AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  final List<Suggestion> suggestions;
  final Function(Suggestion) onSuggestionTap;

  const _SuggestionsPanel({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: GlassContainer(
          key: ValueKey<int>(suggestions.length),
          padding: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(16),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(left: 48),
              child: Divider(color: AppColors.glassStroke, height: 1),
            ),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _PressableScale(
                onTap: () => onSuggestionTap(suggestion),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Icon(suggestion.icon, color: AppColors.textWeak, size: 18),
                  title: Text(
                    suggestion.shortName,
                    style: TextStyle(color: AppColors.text, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    suggestion.address,
                    style: TextStyle(color: AppColors.textWeak, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dense: true,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassVehicleSelector extends StatelessWidget {
  final VehiculeType? selectedVehicle;
  final Function(VehiculeType) onVehicleSelected;
  final VehicleService vehicleService;
  final Color Function(VehicleCategory) getVehicleColor;

  const _GlassVehicleSelector({
    required this.selectedVehicle,
    required this.onVehicleSelected,
    required this.vehicleService,
    required this.getVehicleColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: StreamBuilder<List<VehiculeType>>(
            stream: vehicleService.getVehiclesStream(),
            initialData: const <VehiculeType>[],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Erreur de chargement des véhicules',
                    style: TextStyle(color: AppColors.hot),
                  ),
                );
              }

              final vehicles = snapshot.data ?? <VehiculeType>[];
              final sortedVehicles = List<VehiculeType>.from(vehicles)
                ..sort((a, b) {
                  if (a.isActive && !b.isActive) return -1;
                  if (!a.isActive && b.isActive) return 1;
                  return 0;
                });

              if (sortedVehicles.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Aucun véhicule disponible pour le moment',
                    style: TextStyle(color: AppColors.textWeak),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sortedVehicles.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppColors.glassStroke,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final vehicle = sortedVehicles[index];
                  final isSelected = selectedVehicle?.id == vehicle.id;
                  final isActive = vehicle.isActive;

                  return Opacity(
                    opacity: isActive ? 1.0 : 0.5,
                    child: _VehicleCard(
                      vehicle: vehicle,
                      isSelected: isSelected,
                      isActive: isActive,
                      onTap: isActive ? () => onVehicleSelected(vehicle) : null,
                      getVehicleColor: getVehicleColor,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehiculeType vehicle;
  final bool isSelected;
  final bool isActive;
  final VoidCallback? onTap;
  final Color Function(VehicleCategory) getVehicleColor;

  const _VehicleCard({
    required this.vehicle,
    required this.isSelected,
    required this.isActive,
    this.onTap,
    required this.getVehicleColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = getVehicleColor(vehicle.category);
    
    return _PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent.withOpacity(0.24) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.28)),
              ),
              child: Icon(
                vehicle.icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: TextStyle(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.category.categoryInFrench} • ${vehicle.capacityDisplay}',
                    style: TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.accent : AppColors.textWeak,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCreateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const _GlassCreateButton({
    required this.onPressed,
    required this.isLoading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    return SizedBox(
      width: double.infinity,
      child: RepaintBoundary(
        child: GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(16),
          child: _PressableScale(
            onTap: isEnabled ? onPressed : null,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? AppColors.accent : AppColors.textWeak,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: isEnabled ? 6 : 0,
                shadowColor: AppColors.accent.withOpacity(0.25),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Subtle header glow under the app bar
class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accent.withOpacity(0.06),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Section wrapper for big panels
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

// Petites légendes/captions sous champs
class _FieldCaption extends StatelessWidget {
  final String text;
  const _FieldCaption({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textWeak,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// Press feedback scale 0.98
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressableScale({required this.child, this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _down(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _scale = 0.98);
  }

  void _up([dynamic _]) {
    if (widget.onTap == null) return;
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _down,
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
