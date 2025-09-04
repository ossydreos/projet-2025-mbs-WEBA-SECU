import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/trip_summary_screen.dart';

class SchedulingScreen extends StatefulWidget {
  final String vehicleName;
  final String departure;
  final String destination;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;

  const SchedulingScreen({
    super.key,
    required this.vehicleName,
    required this.departure,
    required this.destination,
    this.departureCoordinates,
    this.destinationCoordinates,
  });

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String? _estimatedArrival;

  @override
  void initState() {
    super.initState();
    // Définir l'heure par défaut à 22:00 comme dans l'exemple
    _selectedTime = const TimeOfDay(hour: 22, minute: 0);
    _updateEstimatedArrival();
  }

  void _updateEstimatedArrival() {
    if (_selectedTime != null) {
      // Ajouter 13 minutes à l'heure de prise en charge (comme dans l'exemple)
      final arrivalTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      ).add(const Duration(minutes: 13));

      setState(() {
        _estimatedArrival = DateFormat('HH:mm').format(arrivalTime);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(minutes: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Brand.accent,
              onPrimary: Colors.white,
              surface: Brand.bgElev,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateEstimatedArrival();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 22, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Brand.accent,
              onPrimary: Colors.white,
              surface: Brand.bgElev,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _updateEstimatedArrival();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      // Format simple pour aujourd'hui
      final months = [
        'janv.',
        'févr.',
        'mars',
        'avr.',
        'mai',
        'juin',
        'juil.',
        'août',
        'sept.',
        'oct.',
        'nov.',
        'déc.',
      ];
      final month = months[date.month - 1];
      return 'Aujourd\'hui, ${date.day} $month';
    } else {
      // Format simple sans locale française pour éviter l'erreur
      final weekdays = [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche',
      ];
      final months = [
        'janv.',
        'févr.',
        'mars',
        'avr.',
        'mai',
        'juin',
        'juil.',
        'août',
        'sept.',
        'oct.',
        'nov.',
        'déc.',
      ];

      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];

      return '$weekday, ${date.day} $month';
    }
  }

  String _formatTime(TimeOfDay time) {
    // Format 24h au lieu du format américain
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header avec X
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Titre et sous-titre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sélectionner l\'heure de prise en charge',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'De 30 minutes à 90 jours à l\'avance',
                      style: TextStyle(fontSize: 16, color: Brand.text),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Section Date
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectDate,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Heure
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heure de prise en charge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectTime,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedTime != null
                                  ? _formatTime(_selectedTime!)
                                  : 'Sélectionner',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedTime != null
                                    ? Colors.white
                                    : Brand.accent,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedTime == null)
                              Text(
                                'Sélectionner',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Brand.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Note fuseau horaire
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Le fuseau horaire est basé sur le lieu de prise en charge',
                  style: TextStyle(fontSize: 14, color: Brand.text),
                ),
              ),

              const SizedBox(height: 24),

              // Estimation d'arrivée (apparaît seulement si une heure est sélectionnée)
              if (_selectedTime != null && _estimatedArrival != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Heure d\'arrivée estimée: $_estimatedArrival',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.info_outline, size: 16, color: Brand.text),
                    ],
                  ),
                ),

              const Spacer(),

              // Lien conditions générales
              const SizedBox(height: 24),

              // Bouton Continuer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: _selectedTime != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripSummaryScreen(
                                  vehicleName: widget.vehicleName,
                                  departure: widget.departure,
                                  destination: widget.destination,
                                  selectedDate: _selectedDate,
                                  selectedTime: _selectedTime!,
                                  estimatedArrival: _estimatedArrival ?? '',
                                  departureCoordinates:
                                      widget.departureCoordinates,
                                  destinationCoordinates:
                                      widget.destinationCoordinates,
                                ),
                              ),
                            );
                          }
                        : null,
                    label: 'Continuer',
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
