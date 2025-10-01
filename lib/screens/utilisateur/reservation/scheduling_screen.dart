import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/trip_summary_screen.dart';
import 'package:my_mobility_services/data/services/directions_service.dart';

class SchedulingScreen extends StatefulWidget {
  final String vehicleName;
  final String departure;
  final String destination;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;
  final double calculatedPrice; // ✅ AJOUTER LE PRIX CALCULÉ

  const SchedulingScreen({
    super.key,
    required this.vehicleName,
    required this.departure,
    required this.destination,
    required this.calculatedPrice, // ✅ AJOUTER LE PRIX CALCULÉ
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
    _initializeTime();
    _validateInitialDate();
  }
  
  void _validateInitialDate() {
    DateTime zurichTime;
    try {
      zurichTime = tz.TZDateTime.now(tz.getLocation('Europe/Zurich'));
    } catch (e) {
      zurichTime = DateTime.now();
    }
    
    final DateTime minimumDate = DateTime(zurichTime.year, zurichTime.month, zurichTime.day);
    
    // Si la date initiale est dans le passé, la corriger
    if (_selectedDate.isBefore(minimumDate)) {
      setState(() {
        _selectedDate = minimumDate;
      });
    }
  }

  void _initializeTime() {
    try {
      // Définir l'heure par défaut à 30 minutes après l'heure actuelle de Zurich
      final zurichTime = tz.TZDateTime.now(tz.getLocation('Europe/Zurich'));
      final defaultTime = zurichTime.add(const Duration(minutes: 30));
      _selectedTime = TimeOfDay(hour: defaultTime.hour, minute: defaultTime.minute);
    } catch (e) {
      // Fallback vers l'heure locale si la base de données n'est pas encore initialisée
      final now = DateTime.now();
      final defaultTime = now.add(const Duration(minutes: 30));
      _selectedTime = TimeOfDay(hour: defaultTime.hour, minute: defaultTime.minute);
    }
    _updateEstimatedArrival();
  }

  void _updateEstimatedArrival() async {
    if (_selectedTime != null && widget.departureCoordinates != null && widget.destinationCoordinates != null) {
      try {
        // Obtenir le temps de trajet réel via l'API Google Maps
        final directions = await DirectionsService.getDirections(
          origin: widget.departureCoordinates!,
          destination: widget.destinationCoordinates!,
        );

        if (directions != null) {
          final durationMinutes = (directions['durationValue'] / 60).round();
          
          // Créer la date/heure dans le fuseau horaire de Zurich
          final zurichLocation = tz.getLocation('Europe/Zurich');
          final selectedDateTime = tz.TZDateTime(
            zurichLocation,
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
          
          // Ajouter le temps de trajet réel à l'heure de prise en charge
          final arrivalTime = selectedDateTime.add(Duration(minutes: durationMinutes));

          setState(() {
            _estimatedArrival = DateFormat('HH:mm').format(arrivalTime);
          });
        } else {
          // Fallback si l'API ne fonctionne pas
          _setFallbackArrivalTime();
        }
      } catch (e) {
        // Fallback en cas d'erreur
        _setFallbackArrivalTime();
      }
    } else {
      // Fallback si pas de coordonnées
      _setFallbackArrivalTime();
    }
  }

  void _setFallbackArrivalTime() {
    try {
      // Créer la date/heure dans le fuseau horaire de Zurich
      final zurichLocation = tz.getLocation('Europe/Zurich');
      final selectedDateTime = tz.TZDateTime(
        zurichLocation,
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      // Fallback avec 15 minutes par défaut
      final arrivalTime = selectedDateTime.add(const Duration(minutes: 15));

      setState(() {
        _estimatedArrival = DateFormat('HH:mm').format(arrivalTime);
      });
    } catch (e) {
      // Fallback vers l'heure locale si la base de données n'est pas encore initialisée
      final arrivalTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      ).add(const Duration(minutes: 15));

      setState(() {
        _estimatedArrival = DateFormat('HH:mm').format(arrivalTime);
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime zurichTime;
    try {
      zurichTime = tz.TZDateTime.now(tz.getLocation('Europe/Zurich'));
    } catch (e) {
      // Fallback vers l'heure locale si la base de données n'est pas encore initialisée
      zurichTime = DateTime.now();
    }
    
    // S'assurer qu'on ne peut pas sélectionner une date dans le passé
    final DateTime minimumDate = DateTime(zurichTime.year, zurichTime.month, zurichTime.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(minimumDate) ? minimumDate : _selectedDate,
      firstDate: minimumDate,
      lastDate: zurichTime.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.bgElev,
              onSurface: Colors.white,
              secondary: AppColors.accent,
              onSecondary: Colors.white,
            ),
            dialogBackgroundColor: AppColors.bgElev,
            cardColor: AppColors.bgElev,
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
    // Vérifier si la date sélectionnée est aujourd'hui
    DateTime zurichTime;
    try {
      zurichTime = tz.TZDateTime.now(tz.getLocation('Europe/Zurich'));
    } catch (e) {
      zurichTime = DateTime.now();
    }
    
    final DateTime today = DateTime(zurichTime.year, zurichTime.month, zurichTime.day);
    final DateTime selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final bool isToday = selectedDateOnly.isAtSameMomentAs(today);
    
    // Si c'est aujourd'hui, s'assurer que l'heure minimum est dans 30 minutes
    TimeOfDay minimumTime;
    if (isToday) {
      final DateTime minimumDateTime = zurichTime.add(const Duration(minutes: 30));
      minimumTime = TimeOfDay(hour: minimumDateTime.hour, minute: minimumDateTime.minute);
    } else {
      minimumTime = const TimeOfDay(hour: 0, minute: 0);
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? minimumTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.bgElev,
              onSurface: Colors.white,
              secondary: AppColors.accent,
              onSecondary: Colors.white,
            ),
            dialogBackgroundColor: AppColors.bgElev,
            cardColor: AppColors.bgElev,
            timePickerTheme: const TimePickerThemeData(
              hourMinuteTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              hourMinuteColor: AppColors.bgElev,
              dialHandColor: AppColors.accent,
              dialBackgroundColor: AppColors.bgElev,
              entryModeIconColor: AppColors.accent,
              helpTextStyle: TextStyle(color: Colors.white),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true, // Force le format 24h
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      // Validation supplémentaire : s'assurer que l'heure sélectionnée n'est pas dans le passé
      if (isToday) {
        final DateTime selectedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        final DateTime minimumDateTime = zurichTime.add(const Duration(minutes: 30));
        
        if (selectedDateTime.isBefore(minimumDateTime)) {
          // Afficher un message d'erreur
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez sélectionner une heure au moins 30 minutes dans le futur'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      setState(() {
        _selectedTime = picked;
      });
      _updateEstimatedArrival();
    }
  }

  String _formatDate(DateTime date) {
    DateTime zurichTime;
    try {
      zurichTime = tz.TZDateTime.now(tz.getLocation('Europe/Zurich'));
    } catch (e) {
      // Fallback vers l'heure locale si la base de données n'est pas encore initialisée
      zurichTime = DateTime.now();
    }
    
    final now = DateTime(zurichTime.year, zurichTime.month, zurichTime.day);
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
                      style: TextStyle(fontSize: 16, color: AppColors.text),
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
                                    : AppColors.accent,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedTime == null)
                              Text(
                                'Sélectionner',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.accent,
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

              const SizedBox(height: 24),

              // Estimation d'arrivée (apparaît seulement si une heure est sélectionnée)
              if (_selectedTime != null && _estimatedArrival != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Heure d\'arrivée estimée: $_estimatedArrival',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
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
                                  calculatedPrice: widget.calculatedPrice, // ✅ TRANSMETTRE LE PRIX
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
