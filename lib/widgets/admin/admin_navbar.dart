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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: const Border(
          top: BorderSide(color: AppColors.glassStroke, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: StreamBuilder<List<Reservation>>(
          // STREAMBUILDER INTÉGRÉ
          stream: Stream.fromFuture(
            _reservationService.getPendingReservations(),
          ),
          builder: (context, snapshot) {
            final pendingCount = snapshot.hasData ? snapshot.data!.length : 0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.inbox_outlined,
                  activeIcon: Icons.inbox,
                  label: 'Demandes',
                  badgeCount: pendingCount, // PASTILLE AUTOMATIQUE
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.schedule_outlined,
                  activeIcon: Icons.schedule,
                  label: 'Courses',
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Gestion',
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Compte',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0, // PARAMÈTRE OPTIONNEL
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              // STACK POUR LA PASTILLE
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.accent : AppColors.textWeak,
                  size: isSelected ? 26 : 24,
                ),
                if (badgeCount > 0) // Pastille conditionnelle
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors
                                .black54, // Ombre plus marquée pour contraste
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight
                              .w900, // Extra bold pour plus de contraste
                          fontFamily: 'Poppins',
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors
                                  .black87, // Ombre du texte pour le faire ressortir
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.textWeak,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
