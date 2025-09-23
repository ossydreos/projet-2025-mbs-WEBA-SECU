import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import '../../data/services/reservation_service.dart';
import '../../data/models/reservation.dart';

class AdminBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final ReservationService _reservationService = ReservationService(); // AJOUT

  AdminBottomNavigationBar({
    // Suppression du const
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      elevation: 0,
      enableFeedback: true,
      items: [
        BottomNavigationBarItem(
          icon: StreamBuilder<List<Reservation>>(
            stream: Stream.fromFuture(_reservationService.getPendingReservations()),
            builder: (context, snapshot) {
              final pendingCount = snapshot.hasData ? snapshot.data!.length : 0;
              return Stack(
                children: [
                  const Icon(Icons.inbox_outlined),
                  if (pendingCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          pendingCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          activeIcon: const Icon(Icons.inbox),
          label: 'Demandes',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.schedule_outlined),
          activeIcon: Icon(Icons.schedule),
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

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: bar,
    );
  }

}
