import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme/theme_app.dart';

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
      distance: _calculateDistance(
        json,
      ), // Vous pouvez implémenter le calcul de distance
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
  bool _isLoading = false;
  String _currentPickupLocation =
      "Chemin du Domaine-Patry 1"; // Valeur fixe pour correspondre aux images

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
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
    // Retourner les données à l'écran principal
    Navigator.pop(context, {
      'address': suggestion.shortName,
      'coordinates': suggestion.coordinates,
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header avec boutons et titre
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              children: [
                // Barre de titre
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Votre itinéraire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.sort, size: 24, color: Colors.black),
                  ],
                ),

                const SizedBox(height: 20),

                // Point de départ (fixe)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentPickupLocation,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.add, color: Colors.black54, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Zone de recherche destination
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: Colors.grey, size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Destination',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: _clearSearch,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des suggestions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestions.isEmpty && _searchController.text.isNotEmpty
                ? const Center(
                    child: Text(
                      'Aucun résultat trouvé',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: Icon(
                          suggestion.icon,
                          color: Colors.black54,
                          size: 24,
                        ),
                        title: Text(
                          suggestion.shortName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: suggestion.address.isNotEmpty
                            ? Text(
                                suggestion.address,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Text(
                          suggestion.distance,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        onTap: () => _onSuggestionTap(suggestion),
                      );
                    },
                  ),
          ),

          // Footer "powered by Google" (comme dans vos images)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'powered by Google',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
