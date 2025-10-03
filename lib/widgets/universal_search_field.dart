import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_suggestion.dart';
import '../services/google_places_service.dart';
import '../utils/debounce_timer.dart';

/// Widget universel pour tous les champs de recherche de lieux
/// Remplace les 388 lignes dupliquées dans address_suggestion_field.dart
class UniversalSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final String? initialValue;
  final Function(String address, LatLng? coordinates) onSelectionChanged;
  final String? Function(String? value)? validator;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? contentPadding;

  const UniversalSearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.initialValue,
    required this.onSelectionChanged,
    this.validator,
    this.suffixIcon,
    this.controller,
    this.textStyle,
    this.contentPadding,
  });

  @override
  State<UniversalSearchField> createState() => _UniversalSearchFieldState();
}

class _UniversalSearchFieldState extends State<UniversalSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final DebounceTimer _debouncer = DebounceTimer(const Duration(milliseconds: 300));

  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  String? _errorMessage;

  TextEditingController get _effectiveController => widget.controller ?? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.controller == null) {
      _effectiveController.text = widget.initialValue!;
    }
    _effectiveController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  /// Listener pour les changements de texte
  void _onTextChanged() {
    final query = _effectiveController.text;
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _errorMessage = null;
      });
      return;
    }
    _debouncer(() => _fetchSuggestions(query));
  }

  /// Listener pour les changements de focus
  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  /// Récupère les suggestions via le service centralisé
  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final suggestions = await GooglePlacesService.instance.fetchSuggestions(query);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
          _showSuggestions = _focusNode.hasFocus;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
          _showSuggestions = false;
          _errorMessage = 'Erreur: $e';
        });
      }
    }
  }

  /// Gère la sélection d'une suggestion
  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    LatLng? coords = suggestion.coordinates;
    if (coords == null && suggestion.placeId != null) {
      coords = await GooglePlacesService.instance.getPlaceCoordinates(suggestion.placeId!);
    }

    if (mounted) {
      setState(() {
        _effectiveController.text = suggestion.shortName;
        _suggestions = [];
        _showSuggestions = false;
      });

      widget.onSelectionChanged(suggestion.shortName, coords);
      FocusScope.of(context).unfocus();
    }
  }

  /// Construit l'item de suggestion dans la liste
  Widget _buildSuggestionItem(PlaceSuggestion suggestion) {
    return ListTile(
      leading: Icon(suggestion.icon, color: Colors.blue),
      title: Text(suggestion.shortName),
      subtitle: suggestion.address.isNotEmpty ? Text(suggestion.address) : null,
      onTap: () => _onSuggestionTap(suggestion),
      dense: true,
    );
  }

  /// Construit la liste des suggestions
  Widget _buildSuggestionsList() {
    if (!_showSuggestions || _suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[600]),
              ),
            )
          else
            ..._suggestions.take(5).map(_buildSuggestionItem),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Champ de texte
        TextFormField(
          controller: _effectiveController,
          focusNode: _focusNode,
          validator: widget.validator,
          style: widget.textStyle,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: widget.suffixIcon,
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Liste des suggestions
        _buildSuggestionsList(),
      ],
    );
  }
}
