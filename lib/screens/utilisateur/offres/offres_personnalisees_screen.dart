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
    // Nouveau style aéré pleine largeur pour l'attente d'acceptation
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau de statut
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.orange, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'En attente d\'acceptation du chauffeur',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  _formatDate(offer.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bloc trajet + heures (même gabarit que carte acceptée)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                    Container(width: 1, height: 22, color: AppColors.textWeak.withOpacity(0.5)),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.departure, style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.25)),
                      const SizedBox(height: 8),
                      Text(offer.destination, style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.25)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Début', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    Text(
                      offer.startDateTime != null
                          ? '${offer.startDateTime!.hour.toString().padLeft(2, '0')}:${offer.startDateTime!.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                      style: TextStyle(color: AppColors.textStrong, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('Fin', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    Text(
                      offer.endDateTime != null
                          ? '${offer.endDateTime!.hour.toString().padLeft(2, '0')}:${offer.endDateTime!.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                      style: TextStyle(color: AppColors.textStrong, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Ligne infos date + à définir
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textWeak),
                const SizedBox(width: 8),
                Text(
                  offer.startDateTime != null
                      ? '${offer.startDateTime!.day}/${offer.startDateTime!.month}/${offer.startDateTime!.year}'
                      : 'Date non définie',
                  style: TextStyle(color: AppColors.textWeak, fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.account_balance_wallet, size: 16, color: AppColors.textWeak),
                const SizedBox(width: 8),
                Text('À définir', style: TextStyle(color: AppColors.textWeak, fontSize: 14)),
              ],
            ),

            if (offer.clientNote != null && offer.clientNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.clientNote!,
                        style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedOfferCard(CustomOffer offer) {
    // Nouveau style: carte premium, hiérarchie claire, alignements propres
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offre personnalisée',
                        style: TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chauffeur: ${offer.driverName ?? 'Non spécifié'}',
                        style: TextStyle(color: AppColors.textWeak, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Price badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${offer.proposedPrice?.toStringAsFixed(2) ?? '0.00'} CHF',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Prix proposé',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Trip block (départ -> arrivée) avec points et ligne
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Column(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                    Container(width: 1, height: 22, color: AppColors.textWeak.withOpacity(0.5)),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.departure,
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.destination,
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Heures
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Début', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    Text(
                      offer.startDateTime != null
                          ? '${offer.startDateTime!.hour.toString().padLeft(2, '0')}:${offer.startDateTime!.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                      style: TextStyle(color: AppColors.textStrong, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('Fin', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    Text(
                      offer.endDateTime != null
                          ? '${offer.endDateTime!.hour.toString().padLeft(2, '0')}:${offer.endDateTime!.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                      style: TextStyle(color: AppColors.textStrong, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Date + note chauffeur
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textWeak),
                const SizedBox(width: 8),
                Text(
                  offer.startDateTime != null
                      ? '${offer.startDateTime!.day}/${offer.startDateTime!.month}/${offer.startDateTime!.year}'
                      : 'Date non définie',
                  style: TextStyle(color: AppColors.textWeak, fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.account_balance_wallet, size: 16, color: AppColors.textWeak),
                const SizedBox(width: 8),
                Text('À définir', style: TextStyle(color: AppColors.textWeak, fontSize: 14)),
              ],
            ),

            if (offer.driverMessage != null && offer.driverMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.message, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        offer.driverMessage!,
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmAndPayOffer(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Valider et payer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectOffer(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Refuser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
        vehicleName: offer.vehicleName?.isNotEmpty == true
            ? offer.vehicleName!
            : 'Offre personnalisée',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  
                  const SizedBox(height: 12),
                  
                  if (pendingOffer != null) ...[
                    // Afficher l'offre en attente avec style amélioré
                    // Carte pleine largeur
                    SizedBox(width: double.infinity, child: _buildPendingOfferCard(pendingOffer)),
                    const SizedBox(height: 20),
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
                    SizedBox(width: double.infinity, child: _buildAcceptedOfferCard(acceptedOffer)),
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
