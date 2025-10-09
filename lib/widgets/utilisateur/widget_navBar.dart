// lib/widgets/custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/reservation.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool noWrapper;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.noWrapper = false,
  });

  // Vérifier s'il y a des réservations en cours
  Future<bool> _hasInProgressReservations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: ReservationStatus.inProgress.name)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getInProgressReservationsStream(),
      builder: (context, snapshot) {
        final hasInProgress = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        
        final bar = BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.text,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
          elevation: 0, // Supprimer l'ombre par défaut
          enableFeedback: true, // Activer le retour haptique
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppLocalizations.of(context).home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.local_offer_outlined),
              activeIcon: const Icon(Icons.local_offer),
              label: AppLocalizations.of(context).offers,
            ),
            BottomNavigationBarItem(
              icon: _buildTripsIcon(hasInProgress),
              activeIcon: _buildTripsIcon(hasInProgress, isActive: true),
              label: AppLocalizations.of(context).trips,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppLocalizations.of(context).profile,
            ),
          ],
        );

        // Disable ripple/highlight for smoother interactions over blurred backgrounds
        final barThemed = Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: bar,
        );

        if (noWrapper) return RepaintBoundary(child: barThemed);

        return RepaintBoundary(
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: barThemed,
          ),
        );
      },
    );
  }

  // Stream pour écouter les réservations en cours
  Stream<QuerySnapshot> _getInProgressReservationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: ReservationStatus.inProgress.name)
        .snapshots();
  }

  // Construire l'icône des trajets avec pastille rouge
  Widget _buildTripsIcon(bool hasInProgress, {bool isActive = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isActive ? Icons.schedule : Icons.schedule_outlined,
          color: isActive ? AppColors.accent : AppColors.text,
        ),
        // Afficher la pastille seulement si on n'est pas dans l'onglet trajets
        if (hasInProgress && !isActive)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
