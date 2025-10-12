import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/constants.dart';

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

class AddressSuggestionField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final String? initialValue;
  final Function(String address, LatLng? coordinates) onAddressSelected;
  final String? Function(String? value)? validator;

  const AddressSuggestionField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.initialValue,
    required this.onAddressSelected,
    this.validator,
  });

  @override
  State<AddressSuggestionField> createState() => _AddressSuggestionFieldState();
}

class _AddressSuggestionFieldState extends State<AddressSuggestionField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _debouncer = _Debouncer(const Duration(milliseconds: 300));
  final String _placesSessionToken = DateTime.now().microsecondsSinceEpoch.toString();

  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  String? _placesErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text;
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debouncer(() => _fetchSuggestions(query));
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _placesErrorMessage = null;
    });

    try {
      final key = await AppConstants.googlePlacesWebKey;
      
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
            _showSuggestions = _focusNode.hasFocus;
          });
        } else {
          final err = (data['error_message'] ?? status).toString();
          debugPrint('Places Autocomplete error: $status - $err');
          setState(() {
            _isLoading = false;
            _suggestions = [];
            _showSuggestions = false;
            _placesErrorMessage = err;
          });
        }
      } else {
        debugPrint('Places Autocomplete HTTP ${response.statusCode}: ${response.body}');
        setState(() {
          _isLoading = false;
          _suggestions = [];
          _showSuggestions = false;
          _placesErrorMessage = 'Erreur réseau (${response.statusCode})';
        });
      }
    } catch (e) {
      debugPrint('Places Autocomplete exception: $e');
      setState(() {
        _isLoading = false;
        _suggestions = [];
        _showSuggestions = false;
        _placesErrorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _onSuggestionTap(Suggestion suggestion) async {
    LatLng? coords = suggestion.coordinates;
    if (coords == null && suggestion.placeId != null) {
      coords = await _fetchPlaceDetailsLatLng(suggestion.placeId!);
    }

    setState(() {
      _controller.text = suggestion.shortName;
      _suggestions = [];
      _showSuggestions = false;
    });

    widget.onAddressSelected(suggestion.shortName, coords);
    FocusScope.of(context).unfocus();
  }

  Future<LatLng?> _fetchPlaceDetailsLatLng(String placeId) async {
    try {
      final key = await AppConstants.googlePlacesWebKey;
      
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

  Widget _buildSuggestionsList() {
    if (!_showSuggestions) return const SizedBox.shrink();

    if (_isLoading) {
      return GlassContainer(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _suggestions.take(5).map((suggestion) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onSuggestionTap(suggestion),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(suggestion.icon, color: AppColors.accent, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.shortName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textStrong,
                            ),
                          ),
                          if (suggestion.address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              suggestion.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textWeak,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            style: TextStyle(color: AppColors.textStrong),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: TextStyle(color: AppColors.textWeak),
              hintText: widget.hint,
              hintStyle: TextStyle(color: AppColors.textWeak.withOpacity(0.7)),
              prefixIcon: Icon(widget.prefixIcon, color: AppColors.accent),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: widget.validator,
          ),
        ),
        _buildSuggestionsList(),
      ],
    );
  }
}
