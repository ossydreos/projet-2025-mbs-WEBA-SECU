import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/custom_offer_creation_screen.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
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

class _OffresPersonnaliseesScreenState extends State<OffresPersonnaliseesScreen>
    with AutomaticKeepAliveClientMixin {
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

  // ======================
  // UI HELPERS (PRIVATE)
  // ======================

  Widget _buildPendingOfferCard(CustomOffer offer) {
    final dateText = offer.startDateTime != null
        ? '${offer.startDateTime!.day}/${offer.startDateTime!.month}/${offer.startDateTime!.year}'
        : 'Date non définie';

    return _GlassPanel(
      borderRadius: const BorderRadius.all(Fx.radiusM),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: status chip + relative date
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusChip(
                label: 'En attente d\'acceptation',
                icon: Icons.schedule,
                color: AppColors.accent,
              ),
              const Spacer(),
              Text(
                _formatDate(offer.createdAt),
                style: TextStyle(color: AppColors.textWeak, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Addresses + times
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AddressBlock(
                  from: offer.departure,
                  to: offer.destination,
                ),
              ),
              const SizedBox(width: 12),
              _TimesBlock(
                start: offer.startDateTime,
                end: offer.endDateTime,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info line: date + wallet
          _InfoLine(
            leftIcon: Icons.calendar_today,
            leftText: dateText,
            rightIcon: Icons.account_balance_wallet,
            rightText: 'À définir',
          ),

          if (offer.clientNote != null && offer.clientNote!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SubGlassNote(
              icon: Icons.note,
              accent: AppColors.accent,
              text: offer.clientNote!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptedOfferCard(CustomOffer offer) {
    final dateText = offer.startDateTime != null
        ? '${offer.startDateTime!.day}/${offer.startDateTime!.month}/${offer.startDateTime!.year}'
        : 'Date non définie';

    return _GlassPanel(
      borderRadius: const BorderRadius.all(Fx.radiusM),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Price badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundedGlyph(
                icon: Icons.check_circle,
                bg: AppColors.accent.withOpacity(0.18),
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderTitleSubtitle(
                  title: 'Offre personnalisée',
                  subtitle: 'Chauffeur: ${offer.driverName ?? 'Non spécifié'}',
                ),
              ),
              const SizedBox(width: 8),
              _PriceBadge(
                amountLabel: '${offer.proposedPrice?.toStringAsFixed(2) ?? '0.00'} CHF',
                caption: 'Prix proposé',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Addresses + times
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AddressBlock(
                  from: offer.departure,
                  to: offer.destination,
                ),
              ),
              const SizedBox(width: 12),
              _TimesBlock(
                start: offer.startDateTime,
                end: offer.endDateTime,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info line
          _InfoLine(
            leftIcon: Icons.calendar_today,
            leftText: dateText,
            rightIcon: Icons.account_balance_wallet,
            rightText: 'À définir',
          ),

          if (offer.driverMessage != null && offer.driverMessage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SubGlassNote(
              icon: Icons.message,
              accent: AppColors.accent,
              text: offer.driverMessage!,
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          _ActionsRow(
            primaryLabel: 'Valider et payer',
            primaryOnPressed: () => _confirmAndPayOffer(offer),
            primaryColor: AppColors.accent2,
            secondaryLabel: 'Refuser',
            secondaryOnPressed: () => _rejectOffer(offer),
            secondaryColor: AppColors.hot,
          ),
        ],
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
        type: ReservationType.offer, // Marquer comme offre personnalisée
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
        if (refreshed != null && refreshed.status == ReservationStatus.confirmed) {
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
        status: ReservationStatus.cancelled,
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
        'status': 'cancelled',
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
        // Forcer le rafraîchissement de l'interface
        setState(() {});
        
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scaffold = Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: AppLocalizations.of(context).offers),
        body: StreamBuilder<List<CustomOffer>>(
          stream: _customOfferService.getUserCustomOffers(),
          initialData: const <CustomOffer>[],
          builder: (context, snapshot) {
            final hasAnyData = (snapshot.data != null && snapshot.data!.isNotEmpty);
            if (snapshot.connectionState == ConnectionState.waiting && !hasAnyData) {
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
            final pendingOffer = offers.where((o) => o.status == ReservationStatus.pending).isNotEmpty
                ? offers.where((o) => o.status == ReservationStatus.pending).first
                : null;
            
            final acceptedOffer = offers.where((o) => o.status == ReservationStatus.confirmed).isNotEmpty
                ? offers.where((o) => o.status == ReservationStatus.confirmed).first
                : null;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (pendingOffer == null && acceptedOffer == null) ...[
                      _GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Créez une demande personnalisée pour un chauffeur privé',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    if (pendingOffer != null) ...[
                      // Pending Card
                      _buildPendingOfferCard(pendingOffer),
                      const SizedBox(height: 20),
                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _cancelPendingOffer(pendingOffer),
                          icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                          label: const Text(
                            'Annuler cette offre',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.hot,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ] else if (acceptedOffer != null) ...[
                      // Accepted Card
                      _buildAcceptedOfferCard(acceptedOffer),
                    ] else ...[
                      // Create CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openCustomOfferCreation(context),
                          icon: const Icon(Icons.add, color: Colors.white, size: 20),
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // How it works
                      _GlassPanel(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _SectionTitle(
                              icon: Icons.info_outline,
                              title: 'Comment ça marche ?',
                            ),
                            SizedBox(height: 12),
                            _HowItWorksList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );

    return widget.showBottomBar ? GlassBackground(child: scaffold) : scaffold;
  }
}

// ======================
// SUB-WIDGETS (PRIVATE)
// ======================

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = const BorderRadius.all(Fx.radiusM),
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassContainer(
        padding: padding,
        margin: margin,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String from;
  final String to;

  const _AddressBlock({
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textWeak.withOpacity(0.75);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            ),
            Container(width: 1, height: 24, color: secondary),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AddressLine(
                icon: Icons.place,
                text: from,
                color: AppColors.accent,
              ),
              const SizedBox(height: 8),
              _AddressLine(
                icon: Icons.flag,
                text: to,
                color: const Color(0xFFFF6B6B),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _AddressLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: AppColors.text, fontSize: 14, height: 1.25);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TimesBlock extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;

  const _TimesBlock({
    required this.start,
    required this.end,
  });

  String _hhmm(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(AppLocalizations.of(context).start, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        Text(
          _hhmm(start),
          style: TextStyle(color: AppColors.textStrong, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context).end, style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
        Text(
          _hhmm(end),
          style: TextStyle(color: AppColors.textStrong, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData leftIcon;
  final String leftText;
  final IconData rightIcon;
  final String rightText;

  const _InfoLine({
    required this.leftIcon,
    required this.leftText,
    required this.rightIcon,
    required this.rightText,
  });

  @override
  Widget build(BuildContext context) {
    final weak = AppColors.textWeak;
    return Row(
      children: [
        Icon(leftIcon, size: 16, color: weak),
        const SizedBox(width: 8),
        Text(leftText, style: TextStyle(color: weak, fontSize: 14)),
        const Spacer(),
        Icon(rightIcon, size: 16, color: weak),
        const SizedBox(width: 8),
        Text(rightText, style: TextStyle(color: weak, fontSize: 14)),
      ],
    );
  }
}

class _SubGlassNote extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String text;

  const _SubGlassNote({
    required this.icon,
    required this.accent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedGlyph extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final double size;

  const _RoundedGlyph({
    required this.icon,
    required this.bg,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _HeaderTitleSubtitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderTitleSubtitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textStrong,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textWeak, fontSize: 12),
        ),
      ],
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String amountLabel;
  final String caption;

  const _PriceBadge({
    required this.amountLabel,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amountLabel,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            caption,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback primaryOnPressed;
  final Color primaryColor;
  final String secondaryLabel;
  final VoidCallback secondaryOnPressed;
  final Color secondaryColor;

  const _ActionsRow({
    required this.primaryLabel,
    required this.primaryOnPressed,
    required this.primaryColor,
    required this.secondaryLabel,
    required this.secondaryOnPressed,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: primaryOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(primaryLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: secondaryOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(secondaryLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HowItWorksList extends StatelessWidget {
  const _HowItWorksList();

  @override
  Widget build(BuildContext context) {
    return Text(
      '1. Définissez votre trajet et la durée souhaitée\n'
      '2. Ajoutez une note pour le chauffeur\n'
      '3. Les chauffeurs verront votre demande\n'
      '4. Un chauffeur acceptera et proposera un prix\n'
      '5. Vous confirmez et payez',
      style: TextStyle(
        color: AppColors.text,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}
