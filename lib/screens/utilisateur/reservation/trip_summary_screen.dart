import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/services/vehicle_service.dart';
import 'package:my_mobility_services/data/services/directions_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:latlong2/latlong.dart';

class TripSummaryScreen extends StatefulWidget {
  final String vehicleName;
  final String departure;
  final String destination;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String estimatedArrival;
  final LatLng? departureCoordinates;
  final LatLng? destinationCoordinates;

  const TripSummaryScreen({
    super.key,
    required this.vehicleName,
    required this.departure,
    required this.destination,
    required this.selectedDate,
    required this.selectedTime,
    required this.estimatedArrival,
    this.departureCoordinates,
    this.destinationCoordinates,
  });

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  String _paymentMethod = 'Espèces';
  String _totalPrice = '0,00 €';
  final ReservationService _reservationService = ReservationService();
  final VehicleService _vehicleService = VehicleService();
  bool _isCreatingReservation = false;
  double _calculatedPrice = 0.0;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
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
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    _calculatePrice();
  }

  // Calculer le prix basé sur la distance et le type de véhicule
  Future<void> _calculatePrice() async {
    try {
      // Obtenir le véhicule sélectionné
      final vehicles = await _vehicleService.getActiveVehicles();
      final selectedVehicle = vehicles.firstWhere(
        (v) => v.name == widget.vehicleName,
        orElse: () => vehicles.isNotEmpty ? vehicles.first : throw Exception('Aucun véhicule trouvé'),
      );
      
      print('🚗 Véhicule sélectionné pour la réservation: ${selectedVehicle.name} (${selectedVehicle.category.name}) - ${selectedVehicle.pricePerKm}€/km');

      // Calculer la distance réelle avec Google Maps
      double distance = 5.0; // Distance par défaut
      if (widget.departureCoordinates != null && widget.destinationCoordinates != null) {
        try {
          distance = await DirectionsService.getRealDistance(
            origin: widget.departureCoordinates!,
            destination: widget.destinationCoordinates!,
          );
          
          // Distance minimum de 1km
          if (distance < 1.0) {
            distance = 1.0;
          }
        } catch (e) {
          print('Erreur lors du calcul de la distance réelle: $e');
          // Fallback avec la formule de Haversine
          final lat1 = widget.departureCoordinates!.latitude;
          final lon1 = widget.departureCoordinates!.longitude;
          final lat2 = widget.destinationCoordinates!.latitude;
          final lon2 = widget.destinationCoordinates!.longitude;
          
          final dLat = (lat2 - lat1) * (3.14159265359 / 180);
          final dLon = (lon2 - lon1) * (3.14159265359 / 180);
          final a = (dLat / 2) * (dLat / 2) + (dLon / 2) * (dLon / 2);
          final c = 2 * (a > 0 ? 1 : -1) * (a.abs() > 1 ? 1 : a.abs());
          distance = (6371 * c).toDouble();
          
          if (distance < 1.0) {
            distance = 1.0;
          }
        }
      }

      // Calculer le prix
      _calculatedPrice = _vehicleService.calculateTripPrice(selectedVehicle, distance);
      
      print('💰 Prix calculé: ${_calculatedPrice.toStringAsFixed(2)} € (distance: ${distance.toStringAsFixed(2)} km)');
      
      setState(() {
        _totalPrice = '${_calculatedPrice.toStringAsFixed(2)} €';
      });
    } catch (e) {
      print('Erreur lors du calcul du prix: $e');
      // Prix par défaut en cas d'erreur
      setState(() {
        _calculatedPrice = 15.0;
        _totalPrice = '15,00 €';
      });
    }
  }

  Future<void> _createReservation() async {
    if (_isCreatingReservation) return;

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      // Obtenir l'ID utilisateur (connecté ou temporaire)
      String userId;
      if (_reservationService.isUserLoggedIn()) {
        userId = _reservationService.getCurrentUserId()!;
      } else {
        // Utilisateur non connecté - créer un ID temporaire
        userId = 'temp_user_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Obtenir le nom d'utilisateur
      String? userName;
      if (_reservationService.isUserLoggedIn()) {
        final user = FirebaseAuth.instance.currentUser;
        userName =
            user?.displayName ?? user?.email?.split('@')[0] ?? 'Utilisateur';
      } else {
        userName = 'Invité';
      }

      // Créer la réservation
      final reservation = Reservation(
        id: '', // Sera généré par le service
        userId: userId,
        userName: userName,
        vehicleName: widget.vehicleName,
        departure: widget.departure,
        destination: widget.destination,
        selectedDate: widget.selectedDate,
        selectedTime: _formatTime(widget.selectedTime),
        estimatedArrival: widget.estimatedArrival,
        paymentMethod: _paymentMethod,
        totalPrice: _calculatedPrice,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        departureCoordinates: widget.departureCoordinates != null
            ? {
                'latitude': widget.departureCoordinates!.latitude,
                'longitude': widget.departureCoordinates!.longitude,
              }
            : null,
        destinationCoordinates: widget.destinationCoordinates != null
            ? {
                'latitude': widget.destinationCoordinates!.latitude,
                'longitude': widget.destinationCoordinates!.longitude,
              }
            : null,
      );

      // Sauvegarder dans Firebase
      print('💾 Sauvegarde de la réservation avec le véhicule: ${widget.vehicleName}');
      final reservationId = await _reservationService.createReservation(
        reservation,
      );
      print('✅ Réservation créée avec l\'ID: $reservationId');

      // Afficher le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réservation créée avec succès ! ID: $reservationId'),
            backgroundColor: AppColors.accent,
          ),
        );

        // Aller directement à l'onglet "Trajets"
        Navigator.pushNamedAndRemoveUntil(context, '/trajets', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la réservation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReservation = false;
        });
      }
    }
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

              // Titre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Passez en revue votre trajet planifié',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Contenu scrollable pour éviter les overflows
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Section Date et heure
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Date and time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: Retourner à la page de planification
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Modifier',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_formatDate(widget.selectedDate)} à ${_formatTime(widget.selectedTime)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: AppColors.textWeak.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                      const SizedBox(height: 24),

                      // Section Itinéraire
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Itinéraire',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    // Retourner à la page de sélection d'adresses
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Modifier',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Visualisation de l'itinéraire
                            Row(
                              children: [
                                // Point de départ (flexible)
                                Flexible(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Adresse de prise en charge',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textWeak,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.departure,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Ligne de connexion
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 2,
                                        color: AppColors.textWeak.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Point d'arrivée (flexible)
                                Flexible(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.text,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Adresse de destination',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textWeak,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.destination,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: AppColors.textWeak.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                      const SizedBox(height: 24),

                      // Section Paiement
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Paiement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: Ouvrir sélection de méthode de paiement
                                    _showPaymentMethodDialog();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Modifier',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                // Logo méthode de paiement
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _paymentMethod,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _totalPrice,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // fin contenu scrollable
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bouton Confirmer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreatingReservation
                            ? null
                            : _createReservation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isCreatingReservation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Confirmer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Méthode de paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.apple),
                title: const Text('Apple Pay'),
                onTap: () {
                  setState(() {
                    _paymentMethod = 'Apple Pay';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Carte bancaire'),
                onTap: () {
                  setState(() {
                    _paymentMethod = 'Carte bancaire';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Espèces'),
                onTap: () {
                  setState(() {
                    _paymentMethod = 'Espèces';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
