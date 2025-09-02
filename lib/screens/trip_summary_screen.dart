import 'package:flutter/material.dart';
import '../theme/theme_app.dart';

class TripSummaryScreen extends StatefulWidget {
  final String vehicleName;
  final String departure;
  final String destination;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String estimatedArrival;

  const TripSummaryScreen({
    super.key,
    required this.vehicleName,
    required this.departure,
    required this.destination,
    required this.selectedDate,
    required this.selectedTime,
    required this.estimatedArrival,
  });

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  String _paymentMethod = 'Espèces';
  String _totalPrice = '28,1 €';

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      final months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
      final month = months[date.month - 1];
      return 'Aujourd\'hui, ${date.day} $month';
    } else {
      final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      final months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
      
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

            const SizedBox(height: 32),

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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            Divider(color: AppColors.textSecondary.withOpacity(0.3), thickness: 0.5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      // Point de départ
                      Column(
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.departure,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Ligne de connexion
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 2,
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Point d'arrivée
                      Column(
                        children: [
                                                     Container(
                             width: 12,
                             height: 12,
                             decoration: BoxDecoration(
                               color: AppColors.surface,
                               shape: BoxShape.circle,
                             ),
                           ),
                          const SizedBox(height: 8),
                          Text(
                            'Adresse de destination',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.destination,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: AppColors.textSecondary.withOpacity(0.3), thickness: 0.5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                           color: AppColors.background,
                           size: 24,
                         ),
                       ),
                       const SizedBox(width: 12),
                       const Text(
                         'Espèces',
                         style: TextStyle(
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

            const Spacer(),

            // Bouton Confirmer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Confirmer la réservation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Course ${widget.vehicleName} confirmée pour ${_formatDate(widget.selectedDate)} à ${_formatTime(widget.selectedTime)}'),
                            backgroundColor: AppColors.accent,
                          ),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                                             child: const Text(
                         'Confirmer',
                         style: TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                           color: Colors.black,
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
