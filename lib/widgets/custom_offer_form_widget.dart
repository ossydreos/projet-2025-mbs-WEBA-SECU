import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_suggestion.dart';
import '../services/offer_management_service.dart';
import '../services/google_places_service.dart';
import '../utils/logging_service.dart';
import '../utils/debounce_timer.dart';
import '../utils/loading_mixin.dart';
import 'universal_search_field.dart';

/// Widget centralisé pour la création d'offres personnalisées
/// Remplace les 1101 lignes du monstre custom_offer_creation_screen.dart
class CustomOfferFormWidget extends StatefulWidget {
  final Function(LatLng?, LatLng?, DateTime, int) onOfferReady;
  final VoidCallback? onCancel;

  const CustomOfferFormWidget({
    super.key,
    required this.onOfferReady,
    this.onCancel,
  });

  @override
  State<CustomOfferFormWidget> createState() => _CustomOfferFormWidgetState();
}

class _CustomOfferFormWidgetState extends State<CustomOfferFormWidget> with LoadingMixin {
  // Services centralisés
  final OfferManagementService _offerService = OfferManagementService.instance;
  final DebounceTimer _distanceDebouncer = DebounceTimer(const Duration(milliseconds: 500));

  // Contrôleurs pour les formulaires
  LatLng? _departureLocation;
  LatLng? _destinationLocation;
  DateTime _selectedDateTime = DateTime.now();
  int _passengerCount = 1;
  
  // Cache pour éviter les appels répétés
  double? _cachedDistance;
  DateTime? _lastDistanceCalculation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            'Créer une offre personnalisée',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Champ départ
          UniversalSearchField(
            label: 'Point de départ',
            hint: 'Entrez votre adresse de départ',
            prefixIcon: Icons.location_on,
            onSelectionChanged: _onDepartureChanged,
          ),
          const SizedBox(height: 16),

          // Champ destination
          UniversalSearchField(
            label: 'Destination',
            hint: 'Entrez votre destination',
            prefixIcon: Icons.flag,
            onSelectionChanged: _onDestinationChanged,
          ),
          const SizedBox(height: 16),

          // Sélecteur de date/heure si lieux sélectionnés
          if (_departureLocation != null && _destinationLocation != null) ...[
            _buildDateTimeSelector(),
            const SizedBox(height: 16),
            _buildPassengerSelector(),
            const SizedBox(height: 16),
            _buildPriceEstimator(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  /// Construit le sélecteur de date/heure
  Widget _buildDateTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Heure',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit le sélecteur de passagers
  Widget _buildPassengerSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nombre de passagers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _passengerCount > 1 ? () => setState(() => _passengerCount--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text(
                _passengerCount.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: _passengerCount < 6 ? () => setState(() => _passengerCount++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit l'estimateur de prix
  Widget _buildPriceEstimator() {
    if (_cachedDistance == null) return const SizedBox.shrink();
    
    final pricing = _offerService.calculateOfferPricing(
      distanceKm: _cachedDistance!,
      vehicleType: 'standard',
      pickupTime: _selectedDateTime,
      passengers: _passengerCount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimation',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text('Distance: ${_cachedDistance!.toStringAsFixed(1)} km'),
          Text('Prix estimé: ${pricing.finalPrice.toStringAsFixed(2)} CHF'),
          Text('Arrivée estimée: ${_estimateArrival().toString()}'),
        ],
      ),
    );
  }

  /// Construit les boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _canSubmit() ? _submitOffer : null,
            child: const Text('Créer l\'offre'),
          ),
        ),
      ],
    );
  }

  /// Gère le changement de sélection départ
  void _onDepartureChanged(String address, LatLng? coordinates) {
    setState(() {
      _departureLocation = coordinates;
    });
    _recalculateDistance();
  }

  /// Gère le changement de sélection destination
  void _onDestinationChanged(String address, LatLng? coordinates) {
    setState(() {
      _destinationLocation = coordinates;
    });
    _recalculateDistance();
  }

  /// Recalcule la distance entre les points
  void _recalculateDistance() {
    if (_departureLocation == null || _destinationLocation == null) return;
    
    final now = DateTime.now();
    if (_cachedDistance != null && _lastDistanceCalculation != null && 
        now.difference(_lastDistanceCalculation!).inMinutes < 5) {
      return; // Cache encore valide
    }

    _distanceDebouncer(() => _calculateDistance());
  }

  /// Calcule la distance via le service
  Future<void> _calculateDistance() async {
    if (_departureLocation == null || _destinationLocation == null) return;

    try {
      final distance = await _offerService.calculateDistance(
        _departureLocation!, 
        _destinationLocation!
      );
      
      if (mounted) {
        setState(() {
          _cachedDistance = distance;
          _lastDistanceCalculation = DateTime.now();
        });
      }

      LoggingService.info('Distance calculée: ${distance?.toStringAsFixed(1)} km');
    } catch (e) {
      LoggingService.error('Erreur calcul distance', error: e);
    }
  }

  /// Sélectionne la date
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  /// Sélectionne l'heure
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    
    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  /// Estime l'heure d'arrivée
  DateTime _estimateArrival() {
    final duration = _cachedDistance != null 
        ? Duration(minutes: (_cachedDistance! / 30 * 60).round()) 
        : const Duration(minutes: 15);
    
    return _selectedDateTime.add(duration);
  }

  /// Vérifie si on peut soumettre l'offre
  bool _canSubmit() {
    return _departureLocation != null && 
           _destinationLocation != null &&
           _selectedDateTime.isAfter(DateTime.now());
  }

  /// Soumet l'offre
  void _submitOffer() {
    if (!_canSubmit()) return;
    
    widget.onOfferReady(
      _departureLocation,
      _destinationLocation,
      _selectedDateTime,
      _passengerCount,
    );
    
    LoggingService.userAction('Custom offer created', metadata: {
      'departure': _departureLocation.toString(),
      'destination': _destinationLocation.toString(),
      'datetime': _selectedDateTime.toString(),
      'passengers': _passengerCount,
    });
  }
}
