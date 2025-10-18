// lib/widgets/custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/models/reservation.dart';
import 'package:my_mobility_services/data/services/ride_chat_service.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool noWrapper;
  final bool showHomeIndicator;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.noWrapper = false,
    this.showHomeIndicator = false,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  bool _tripsAcknowledged = true;
  String _tripsSignature = '';
  String _acknowledgedSignature = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getActiveReservationsStream(),
      builder: (context, reservationSnapshot) {
        final reservationDocs = reservationSnapshot.data?.docs ?? const <QueryDocumentSnapshot>[];

        return StreamBuilder<QuerySnapshot>(
          stream: _getUnreadChatThreadsStream(),
          builder: (context, chatSnapshot) {
            final chatDocs = chatSnapshot.data?.docs ?? const <QueryDocumentSnapshot>[];

            final reservationData = <String, Map<String, dynamic>>{};
            for (final doc in reservationDocs) {
              reservationData[doc.id] = doc.data() as Map<String, dynamic>;
            }

            final signature = _buildSignature(reservationData, chatDocs);
            _updateTripsSignature(signature);

            if (widget.currentIndex == 2) {
              _acknowledgeTrips();
            }

            final drawIndicator = !_tripsAcknowledged &&
                signature.isNotEmpty &&
                widget.currentIndex != 2;

            final bar = BottomNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: _handleTap,
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
              elevation: 0,
              enableFeedback: true,
              items: [
                BottomNavigationBarItem(
                  icon: _buildHomeIcon(
                    hasIndicator: widget.showHomeIndicator && widget.currentIndex != 0,
                  ),
                  activeIcon: _buildHomeIcon(hasIndicator: false, isActive: true),
                  label: AppLocalizations.of(context).home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.local_offer_outlined),
                  activeIcon: const Icon(Icons.local_offer),
                  label: AppLocalizations.of(context).offers,
                ),
                BottomNavigationBarItem(
                  icon: _buildTripsIcon(hasIndicator: drawIndicator),
                  activeIcon: _buildTripsIcon(hasIndicator: false, isActive: true),
                  label: AppLocalizations.of(context).trips,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: AppLocalizations.of(context).profile,
                ),
              ],
            );

            final barThemed = Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
              ),
              child: bar,
            );

            if (widget.noWrapper) return RepaintBoundary(child: barThemed);

            return RepaintBoundary(
              child: GlassContainer(
                padding: EdgeInsets.zero,
                child: barThemed,
              ),
            );
          },
        );
      },
    );
  }

  void _handleTap(int index) {
    if (index == 2) {
      _acknowledgeTrips();
    }
    widget.onTap(index);
  }

  Stream<QuerySnapshot> _getActiveReservationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: [
          ReservationStatus.confirmed.name,
          ReservationStatus.inProgress.name,
        ])
        .snapshots();
  }

  Stream<QuerySnapshot> _getUnreadChatThreadsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection(RideChatService.threadsCollection)
        .where('userId', isEqualTo: user.uid)
        .where('unreadForUser', isGreaterThan: 0)
        .snapshots();
  }

  String _buildSignature(
    Map<String, Map<String, dynamic>> reservations,
    List<QueryDocumentSnapshot> chatDocs,
  ) {
    final inProgressParts = <String>[];
    reservations.forEach((id, data) {
      final status = data['status'];
      if (status is! String) return;

      if (status == ReservationStatus.inProgress.name) {
        final updatedAt = _timestampToMillis(data['updatedAt']);
        inProgressParts.add('$id:$updatedAt');
      }
    });

    if (inProgressParts.isEmpty) {
      return '';
    }

    inProgressParts.sort();
    return inProgressParts.join('|');
  }

  void _updateTripsSignature(String signature) {
    if (_tripsSignature == signature) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _tripsSignature = signature;
        _tripsAcknowledged = signature.isEmpty || signature == _acknowledgedSignature;
      });
    });
  }

  void _acknowledgeTrips() {
    if (_tripsAcknowledged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _tripsAcknowledged = true;
        _acknowledgedSignature = _tripsSignature;
      });
    });
  }

  int _timestampToMillis(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  Widget _buildTripsIcon({required bool hasIndicator, bool isActive = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isActive ? Icons.schedule : Icons.schedule_outlined,
          color: isActive ? AppColors.accent : AppColors.text,
        ),
        if (hasIndicator && !isActive)
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

  Widget _buildHomeIcon({required bool hasIndicator, bool isActive = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isActive ? Icons.home : Icons.home_outlined,
          color: isActive ? AppColors.accent : AppColors.text,
        ),
        if (hasIndicator && !isActive)
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
