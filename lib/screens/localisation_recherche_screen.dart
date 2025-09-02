import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme/theme_app.dart'; // ✅ Import corrigé

class Suggestion {
  final String displayName;
  final String shortName;
  final String address;
  final LatLng coordinates;
  final IconData icon;
  final String distance;

  Suggestion({
    required this.displayName,
    required this.shortName,
    required this.address,
    required this.coordinates,
    required this.icon,
    required this.distance,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    final displayName = json['display_name'] ?? '';
    final parts = displayName.split(',');
    final shortName = parts.isNotEmpty ? parts[0].trim() : displayName;
    final address = parts.length > 1
        ? parts.skip(1).join(',').trim()
        : displayName;

    // Déterminer l'icône basée sur le type
    IconData iconData = Icons.location_on;
    if (json['type'] != null) {
      switch (json['type']) {
        case 'aerodrome':
        case 'airport':
          iconData = Icons.flight;
          break;
        case 'railway':
        case 'station':
          iconData = Icons.train;
          break;
        case 'city':
        case 'town':
        case 'village':
          iconData = Icons.location_city;
          break;
        default:
          iconData = Icons.location_on;
      }
    }

    return Suggestion(
      displayName: displayName,
      shortName: shortName,
      address: address,
      coordinates: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
      icon: iconData,
      distance: _calculateDistance(json),
    );
  }

  static String _calculateDistance(Map<String, dynamic> json) {
    // Calcul simplifié - vous pouvez améliorer avec la géolocalisation réelle
    return "${(100 + (json.hashCode % 100)).abs().toStringAsFixed(1)} km";
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

  const LocationSearchScreen({super.key, this.currentDestination});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _debouncer = _Debouncer(const Duration(milliseconds: 300));

  List<Suggestion> _suggestions = [];
  List<Suggestion> _departureSuggestions = [];
  bool _isLoading = false;
  bool _isLoadingDeparture = false;
  String _currentPickupLocation = "Ma position actuelle";
  final TextEditingController _departureController = TextEditingController();
  final FocusNode _departureFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Si on a déjà une destination, l'afficher
    if (widget.currentDestination != null) {
      _searchController.text = widget.currentDestination!;
    }

    // Focus automatique pour faire apparaître le clavier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Écouter les changements de texte
    _searchController.addListener(_onTextChanged);
    _departureController.addListener(_onDepartureTextChanged);
    
    // Écouter les changements de focus (désactivé temporairement)
    // _focusNode.addListener(_onDestinationFocusChanged);
    // _departureFocusNode.addListener(_onDepartureFocusChanged);
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
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _debouncer(() {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=10&countrycodes=fr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data
            .map((item) => Suggestion.fromJson(item))
            .toList();

        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _suggestions = [];
      });
    }
  }

  void _onSuggestionTap(Suggestion suggestion) {
    // Si on est en train de rechercher pour la destination
    if (_focusNode.hasFocus) {
      setState(() {
        _searchController.text = suggestion.shortName;
        _suggestions = [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
    });
  }

  void _onDepartureTextChanged() {
    final query = _departureController.text;
    print('Departure text changed: "$query"');
    if (query.isEmpty) {
      setState(() {
        _departureSuggestions = [];
      });
      return;
    }

    // Appel direct sans debouncer pour tester
    _fetchDepartureSuggestions(query);
  }

  Future<void> _fetchDepartureSuggestions(String query) async {
    if (query.trim().isEmpty) return;
    print('Fetching departure suggestions for: "$query"');

    setState(() {
      _isLoadingDeparture = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=10&countrycodes=fr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data
            .map((item) => Suggestion.fromJson(item))
            .toList();

        setState(() {
          _departureSuggestions = suggestions;
          _isLoadingDeparture = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDeparture = false;
        _departureSuggestions = [];
      });
    }
  }

  void _onDepartureSuggestionTap(Suggestion suggestion) {
    setState(() {
      _currentPickupLocation = suggestion.shortName;
      _departureController.clear();
      _departureSuggestions = [];
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

  bool _canProceed() {
    return _searchController.text.isNotEmpty;
  }

  void _proceedToBooking() {
    // Retourner les données à l'écran principal avec les deux adresses
    Navigator.pop(context, {
      'departure': _currentPickupLocation,
      'destination': _searchController.text,
      'departureCoordinates': null, // À implémenter plus tard
      'destinationCoordinates': null, // À implémenter plus tard
    });
  }

  Widget _buildSuggestionsList() {
    // Debug: Afficher l'état actuel
    print('Debug suggestions:');
    print('Departure text: "${_departureController.text}"');
    print('Destination text: "${_searchController.text}"');
    print('Departure suggestions count: ${_departureSuggestions.length}');
    print('Destination suggestions count: ${_suggestions.length}');
    print('Loading departure: $_isLoadingDeparture');
    print('Loading destination: $_isLoading');
    
    // Si on recherche pour le départ
    if (_departureController.text.isNotEmpty) {
      if (_isLoadingDeparture) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        );
      }
      
      if (_departureSuggestions.isEmpty) {
        return Center(
          child: Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _departureSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _departureSuggestions[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.1),
              ),
            ),
            child: ListTile(
              leading: Icon(
                suggestion.icon,
                color: AppColors.accent,
                size: 24,
              ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Text(
                suggestion.distance,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => _onDepartureSuggestionTap(suggestion),
            ),
          );
        },
      );
    }
    
    // Si on recherche pour la destination
    if (_searchController.text.isNotEmpty) {
      if (_isLoading) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        );
      }
      
      if (_suggestions.isEmpty) {
        return Center(
          child: Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.1),
              ),
            ),
            child: ListTile(
              leading: Icon(
                suggestion.icon,
                color: AppColors.accent,
                size: 24,
              ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Text(
                suggestion.distance,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => _onDepartureSuggestionTap(suggestion),
            ),
          );
        },
      );
    }
    
    // Si aucun champ n'a le focus, ne rien afficher
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // ✅ Background noir
      body: Column(
        children: [
          // Header avec boutons et titre - THÉMATISÉ
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface, // ✅ Surface sombre
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Barre de titre - THÉMATISÉE
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: AppColors.accent, // ✅ Couleur accent
                      ),
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
                    Icon(
                      Icons.sort,
                      size: 24,
                      color: AppColors.textSecondary, // ✅ Couleur secondaire
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Point de départ (cliquable) - THÉMATISÉ
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.background, // ✅ Background noir
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accent, // ✅ Point accent
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
                              color: AppColors.textSecondary, // ✅ Hint secondaire
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.clear,
                              color: AppColors.textSecondary, // ✅ Couleur secondaire
                              size: 20,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.add,
                          color: AppColors.textSecondary, // ✅ Icône secondaire
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Zone de recherche destination - THÉMATISÉE
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.accent, // ✅ Bordure accent
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.background, // ✅ Background noir
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.search,
                          color:
                              AppColors.textSecondary, // ✅ Couleur secondaire
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
                            hintText: 'Destination',
                            hintStyle: TextStyle(
                              color:
                                  AppColors.textSecondary, // ✅ Hint secondaire
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.clear,
                              color: AppColors
                                  .textSecondary, // ✅ Couleur secondaire
                              size: 20,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.accent, // ✅ Couleur accent
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
          Expanded(
            child: Container(
              color: AppColors.background, // ✅ Background noir
              child: _buildSuggestionsList(),
            ),
          ),

          // Footer avec bouton suivant - THÉMATISÉ
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            color: AppColors.surface, // ✅ Surface sombre
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton suivant
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed() ? _proceedToBooking : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Suivant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'powered by OpenStreetMap',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
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
    );
  }
}
