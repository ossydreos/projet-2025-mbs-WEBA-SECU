import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/services/ride_chat_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import '../../data/models/reservation.dart';

class AdminBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AdminBottomNavigationBar> createState() => _AdminBottomNavigationBarState();
}

class _AdminBottomNavigationBarState extends State<AdminBottomNavigationBar> {
  static String _lastAcknowledgedSignature = '';
  static String _lastAcknowledgedDemandSignature = '';

  @override
  Widget build(BuildContext context) {
    final bar = BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
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
          icon: _buildDemandesIcon(isActive: widget.currentIndex == 0),
          activeIcon: _buildDemandesIcon(isActive: true),
          label: 'Demandes',
        ),
        BottomNavigationBarItem(
          icon: _buildCoursesIcon(isActive: widget.currentIndex == 1),
          activeIcon: _buildCoursesIcon(isActive: true),
          label: 'Courses',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Gestion',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Compte',
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

    return RepaintBoundary(
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: barThemed,
      ),
    );
  }

  Widget _buildDemandesIcon({required bool isActive}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _pendingReservationsStream(),
      builder: (context, pendingSnapshot) {
        final pendingCount = pendingSnapshot.hasData ? pendingSnapshot.data!.docs.length : 0;

        return StreamBuilder<QuerySnapshot>(
          stream: _trackedReservationsStream(),
          builder: (context, reservationsSnapshot) {
            final reservationDocs =
                reservationsSnapshot.data?.docs ?? const <QueryDocumentSnapshot>[];

            final reservationData = <String, Map<String, dynamic>>{};
            for (final doc in reservationDocs) {
              reservationData[doc.id] = doc.data() as Map<String, dynamic>;
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _unreadRideChatThreadsStream(),
              builder: (context, chatSnapshot) {
                final chatDocs = chatSnapshot.data?.docs ?? const <QueryDocumentSnapshot>[];
                var hasUnreadChat = false;
                final chatSignatureParts = <String>[];

                for (final doc in chatDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final reservationId = data['reservationId'] as String?;
                  if (reservationId == null) {
                    continue;
                  }

                  final unread = data['unreadForAdmin'];
                  if (unread is! int || unread <= 0) {
                    continue;
                  }

                  final reservationInfo = reservationData[reservationId];
                  if (reservationInfo == null) {
                    continue;
                  }

                  final statusRaw = reservationInfo['status'];
                  if (statusRaw is! String) {
                    continue;
                  }

                  final statusEnum = ReservationStatus.values.firstWhere(
                    (s) => s.name == statusRaw,
                    orElse: () => ReservationStatus.pending,
                  );

                  if (statusEnum == ReservationStatus.pending ||
                      statusEnum == ReservationStatus.confirmed) {
                    hasUnreadChat = true;
                    final lastUpdate = _timestampToMillis(
                      data['lastMessageAt'] ?? data['updatedAt'],
                    );
                    chatSignatureParts.add('$reservationId:$unread:$lastUpdate');
                  }
                }

                chatSignatureParts.sort();
                final demandChatSignature = chatSignatureParts.join('|');

                if (isActive) {
                  _lastAcknowledgedDemandSignature = demandChatSignature;
                  return const Icon(Icons.inbox);
                }

                final hasNewChat = hasUnreadChat &&
                    demandChatSignature.isNotEmpty &&
                    demandChatSignature != _lastAcknowledgedDemandSignature;

                final showIndicator = (pendingCount > 0 || hasNewChat);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.inbox_outlined),
                    if (showIndicator)
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
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCoursesIcon({required bool isActive}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _trackedReservationsStream(),
      builder: (context, reservationsSnapshot) {
        final reservationDocs =
            reservationsSnapshot.data?.docs ?? const <QueryDocumentSnapshot>[];

        final reservationData = <String, Map<String, dynamic>>{};
        for (final doc in reservationDocs) {
          reservationData[doc.id] = doc.data() as Map<String, dynamic>;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _unreadRideChatThreadsStream(),
          builder: (context, chatSnapshot) {
            final chatDocs =
                chatSnapshot.data?.docs ?? const <QueryDocumentSnapshot>[];

            final signature = _buildSignature(reservationData, chatDocs);

            if (isActive) {
              _acknowledgeSignature(signature);
            }

            final acknowledged = _lastAcknowledgedSignature == signature;
            final showIndicator = !isActive && signature.isNotEmpty && !acknowledged;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? Icons.schedule : Icons.schedule_outlined),
                if (showIndicator)
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
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _pendingReservationsStream() {
    return FirebaseFirestore.instance
        .collection('reservations')
        .where('status', isEqualTo: ReservationStatus.pending.name)
        .snapshots();
  }

  Stream<QuerySnapshot> _trackedReservationsStream() {
    return FirebaseFirestore.instance
        .collection('reservations')
        .where('status', whereIn: [
          ReservationStatus.pending.name,
          ReservationStatus.confirmed.name,
          ReservationStatus.inProgress.name,
        ])
        .snapshots();
  }

  Stream<QuerySnapshot> _unreadRideChatThreadsStream() {
    return FirebaseFirestore.instance
        .collection(RideChatService.threadsCollection)
        .where('unreadForAdmin', isGreaterThan: 0)
        .snapshots();
  }

  String _buildSignature(
    Map<String, Map<String, dynamic>> reservations,
    List<QueryDocumentSnapshot> chatDocs,
  ) {
    const trackedStatuses = {
      ReservationStatus.pending,
      ReservationStatus.confirmed,
      ReservationStatus.inProgress,
    };

    final reservationParts = <String>[];
    reservations.forEach((id, data) {
      final statusRaw = data['status'];
      if (statusRaw is String) {
        final statusEnum = ReservationStatus.values.firstWhere(
          (s) => s.name == statusRaw,
          orElse: () => ReservationStatus.pending,
        );
        if (trackedStatuses.contains(statusEnum)) {
          final updatedAt = _timestampToMillis(data['updatedAt']);
          reservationParts.add('$id:$statusRaw:$updatedAt');
        }
      }
    });
    reservationParts.sort();

    final chatParts = <String>[];
    for (final doc in chatDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final reservationId = data['reservationId'] as String?;
      if (reservationId == null) continue;

      final reservationStatusRaw = reservations[reservationId]?['status'];
      if (reservationStatusRaw is String && reservationStatusRaw == ReservationStatus.pending.name) {
        continue;
      }

      final unread = data['unreadForAdmin'] ?? 0;
      final updatedAt = _timestampToMillis(data['updatedAt'] ?? data['lastMessageAt']);
      chatParts.add('${doc.id}:$unread:$updatedAt');
    }
    chatParts.sort();

    if (reservationParts.isEmpty && chatParts.isEmpty) {
      return '';
    }

    return '${reservationParts.join(',')}|${chatParts.join(',')}';
  }

  void _acknowledgeSignature(String signature) {
    _lastAcknowledgedSignature = signature;
  }

  int _timestampToMillis(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    return 0;
  }
}
