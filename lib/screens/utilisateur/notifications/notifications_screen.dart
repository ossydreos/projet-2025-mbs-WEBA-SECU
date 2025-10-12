import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/services/client_notification_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/widgets/notifications/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ClientNotificationService _notificationService =
      ClientNotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context).mustBeConnectedToSeeNotifications),
        ),
      );
    }

    return Theme(
      data: AppTheme.glassDark,
      child: GlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GlassAppBar(
            title: AppLocalizations.of(context).notifications,
            actions: [
              StreamBuilder<int>(
                stream: _notificationService.getUnreadCount(user.uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  if (unreadCount == 0) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: () => _markAllAsRead(user.uid),
                icon: const Icon(Icons.done_all, color: AppColors.accent),
                tooltip: AppLocalizations.of(context).markAllAsRead,
              ),
            ],
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notificationService.getUserNotifications(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: GlassContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.hot,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).errorLoadingNotifications,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: AppColors.textWeak),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: GlassContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.accent.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).noNotifications,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous recevrez des notifications ici quand l\'administrateur modifiera le statut de vos courses.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textWeak,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationCard(
                    id: notification['id'],
                    title: notification['title'],
                    message: notification['message'],
                    type: notification['type'],
                    createdAt: (notification['createdAt'] as Timestamp)
                        .toDate(),
                    isRead: notification['isRead'] ?? false,
                    onTap: () => _markAsRead(notification['id']),
                    onDelete: () => _deleteNotification(notification['id']),
                  );
                },
              );
            },
          ),
          // bottomNavigationBar: const UserBottomNavigationBar(currentIndex: 3),
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              AppLocalizations.of(context).allNotificationsMarkedAsRead,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }
}
