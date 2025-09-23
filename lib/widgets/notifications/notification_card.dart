import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';

class NotificationCard extends StatelessWidget {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône de notification
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getIconColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getIconColor().withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(_getIcon(), color: _getIconColor(), size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Contenu de la notification
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre et indicateur de lecture
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: AppColors.textStrong,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Message
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textWeak,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Date et heure
                        Text(
                          _formatDateTime(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textWeak.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bouton de suppression
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textWeak,
                        size: 18,
                      ),
                      tooltip: 'Supprimer',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case 'reservation_confirmed':
        return Icons.check_circle;
      case 'reservation_refused':
        return Icons.cancel;
      case 'reservation_cancelled':
        return Icons.cancel_outlined;
      case 'reservation_in_progress':
        return Icons.directions_car;
      case 'reservation_completed':
        return Icons.flag;
      case 'reservation_status_changed':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case 'reservation_confirmed':
        return Colors.green;
      case 'reservation_refused':
        return Colors.red;
      case 'reservation_cancelled':
        return Colors.orange;
      case 'reservation_in_progress':
        return AppColors.accent;
      case 'reservation_completed':
        return Colors.blue;
      case 'reservation_status_changed':
        return AppColors.accent;
      default:
        return AppColors.textWeak;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}
