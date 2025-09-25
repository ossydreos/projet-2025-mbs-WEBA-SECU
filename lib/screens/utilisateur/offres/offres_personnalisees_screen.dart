import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/custom_offer_creation_screen.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/reservation_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/generated/app_localizations.dart';

class OffresPersonnaliseesScreen extends StatefulWidget {
  final Function(int) onNavigate;
  final bool showBottomBar;

  const OffresPersonnaliseesScreen({
    super.key,
    required this.onNavigate,
    this.showBottomBar = true,
  });

  @override
  State<OffresPersonnaliseesScreen> createState() => _OffresPersonnaliseesScreenState();
}

class _OffresPersonnaliseesScreenState extends State<OffresPersonnaliseesScreen> {
  final CustomOfferService _customOfferService = CustomOfferService();
  final ReservationService _reservationService = ReservationService();

  void _openCustomOfferCreation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomOfferCreationScreen(),
      ),
    );
  }

  Widget _buildPendingOfferCard(CustomOffer offer) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête simple
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'En attente d\'acceptation du chauffeur',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatDate(offer.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Trajet
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${offer.departure} → ${offer.destination}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Dates et heures
            if (offer.startDateTime != null && offer.endDateTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Début: ${_formatDateTime(offer.startDateTime)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Fin: ${_formatDateTime(offer.endDateTime)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Fallback vers la durée si pas de dates
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${offer.durationHours}h ${offer.durationMinutes}min',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            
            // Note du client (si présente)
            if (offer.clientNote != null && offer.clientNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      offer.clientNote!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedOfferCard(CustomOffer offer) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec prix en évidence
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.8),
                    AppColors.accent.withOpacity(0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Offre acceptée !',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chauffeur: ${offer.driverName ?? 'Non spécifié'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${offer.proposedPrice?.toStringAsFixed(2) ?? '0.00'} CHF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Prix proposé',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Trajet
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${offer.departure} → ${offer.destination}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Dates et heures
            if (offer.startDateTime != null && offer.endDateTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Début: ${_formatDateTime(offer.startDateTime)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Fin: ${_formatDateTime(offer.endDateTime)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Fallback vers la durée si pas de dates
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${offer.durationHours}h ${offer.durationMinutes}min',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            
            // Message du chauffeur (si présent)
            if (offer.driverMessage != null && offer.driverMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.message, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Message du chauffeur:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.driverMessage!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmAndPayOffer(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Valider et payer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectOffer(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Refuser',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Non défini';
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month à ${hour}h$minute';
  }

  Future<void> _confirmAndPayOffer(CustomOffer offer) async {
    try {
      if (offer.proposedPrice == null) {
        throw Exception('Prix manquant sur l\'offre');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // NE PAS créer de réservation maintenant - juste naviguer vers le paiement
      // La réservation sera créée seulement après confirmation du paiement
      
      // Créer un objet réservation temporaire pour l'écran de paiement
      final DateTime selectedDate = offer.startDateTime ?? DateTime.now();
      final int hour = selectedDate.hour;
      final int minute = selectedDate.minute;
      final String selectedTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      final tempReservation = Reservation(
        id: '', // Pas d'ID encore
        userId: user.uid,
        userName: user.displayName ?? user.email?.split('@').first,
        vehicleName: 'Offre personnalisée',
        departure: offer.departure,
        destination: offer.destination,
        selectedDate: selectedDate,
        selectedTime: selectedTime,
        estimatedArrival: '--:--',
        paymentMethod: 'Espèces',
        totalPrice: offer.proposedPrice!,
        status: ReservationStatus.confirmed, // En attente de paiement
        createdAt: DateTime.now(),
        departureCoordinates: offer.departureCoordinates,
        destinationCoordinates: offer.destinationCoordinates,
        clientNote: offer.clientNote,
        customOfferId: offer.id, // Lier à l'offre personnalisée
      );

      // Ouvrir l'écran de paiement IDENTIQUE aux réservations normales
      if (mounted) {
        // Aller vers le paiement
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationDetailScreen(
              reservation: tempReservation,
              customOfferId: offer.id, // Passer l'ID de l'offre pour créer la réservation après paiement
            ),
          ),
        );

        // Au retour, si le paiement est confirmé, l'offre doit disparaître
        final refreshed = await _customOfferService.getCustomOfferById(offer.id);
        if (refreshed != null && refreshed.status == CustomOfferStatus.confirmed) {
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'initialisation du paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectOffer(CustomOffer offer) async {
    try {
      await _customOfferService.updateOfferStatus(
        offerId: offer.id,
        status: CustomOfferStatus.rejected,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelPendingOffer(CustomOffer offer) async {
    try {
      print('=== ANNULATION DIRECTE FIREBASE ===');
      print('Offre ID: ${offer.id}');
      print('Statut actuel: ${offer.status.name}');
      
      // Utiliser directement Firebase
      await FirebaseFirestore.instance
          .collection('custom_offers')
          .doc(offer.id)
          .update({
        'status': 'rejected',
        'updatedAt': Timestamp.now(),
        'cancelledAt': Timestamp.now(),
        'cancelledBy': 'client',
        'cancellationReason': 'Annulé par le client',
      });
      
      print('=== MISE À JOUR FIREBASE RÉUSSIE ===');

      // Si une réservation liée existe déjà, la supprimer pour éviter les doublons
      if (offer.reservationId != null && offer.reservationId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(offer.reservationId)
            .delete();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Offre annulée avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('=== ERREUR FIREBASE ===');
      print('Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: AppLocalizations.of(context).offers),
        body: StreamBuilder<List<CustomOffer>>(
          stream: _customOfferService.getUserCustomOffers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final offers = snapshot.data ?? [];
            
            // Vérifier s'il y a une offre en attente ou acceptée
            final pendingOffer = offers.where((o) => o.status == CustomOfferStatus.pending).isNotEmpty
                ? offers.where((o) => o.status == CustomOfferStatus.pending).first
                : null;
            
            final acceptedOffer = offers.where((o) => o.status == CustomOfferStatus.accepted).isNotEmpty
                ? offers.where((o) => o.status == CustomOfferStatus.accepted).first
                : null;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (pendingOffer == null && acceptedOffer == null) ...[
                    // En-tête seulement si pas d'offre en attente ou acceptée
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star_outline,
                            size: 60,
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).customOffer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez une demande personnalisée pour un chauffeur privé',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  if (pendingOffer != null) ...[
                    // Afficher l'offre en attente avec style amélioré
                    _buildPendingOfferCard(pendingOffer),
                    const SizedBox(height: 16),
                    // Bouton pour annuler l'offre
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelPendingOffer(pendingOffer),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text(
                          'Annuler cette offre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else if (acceptedOffer != null) ...[
                    // Afficher l'offre acceptée avec prix et boutons d'action
                    _buildAcceptedOfferCard(acceptedOffer),
                  ] else ...[
                    // Bouton de création (seulement si pas d'offre en attente)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openCustomOfferCreation(context),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          AppLocalizations.of(context).createCustomOffer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Informations seulement si pas d'offre en attente
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Comment ça marche ?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Définissez votre trajet et la durée souhaitée\n'
                            '2. Ajoutez une note pour le chauffeur\n'
                            '3. Les chauffeurs verront votre demande\n'
                            '4. Un chauffeur acceptera et proposera un prix\n'
                            '5. Vous confirmez et payez',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
