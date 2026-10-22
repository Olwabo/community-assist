import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../member/report/report_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _auth = AuthService();
  final _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.streamCurrentUser(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
                          IconButton(
                tooltip: 'Mark all as read',
                icon: const Icon(Icons.done_all),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _notificationService.markAllAsRead(user.uid);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('All marked as read'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: StreamBuilder<List<AppNotificationModel>>(
              stream:
                  _notificationService.streamUserNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                }

                final notifications =
                    snapshot.data ?? const <AppNotificationModel>[];

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final n = notifications[i];
                    return _NotificationTile(
                      notification: n,
                      onTap: () async {
                        // Mark as read
                        if (!n.isRead) {
                          await _notificationService.markAsRead(n.id);
                        }
                        // Deep link to report
                        if (n.reportId != null && context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportDetailsScreen(
                                reportId: n.reportId!,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "You'll be notified when your reports are updated.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.isRead;

    return Material(
      color: isUnread
          ? AppColors.primary.withValues(alpha: 0.04)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconColor(n.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconData(n.type),
                  size: 20,
                  color: _iconColor(n.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (n.reportNumber != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              n.reportNumber!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatRelativeTime(n.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconData(NotificationType type) {
    switch (type) {
      case NotificationType.statusChange:
        return Icons.swap_horiz;
      case NotificationType.adminResponse:
        return Icons.support_agent;
      case NotificationType.reportResolved:
        return Icons.check_circle_outline;
      case NotificationType.reportRejected:
        return Icons.cancel_outlined;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.statusChange:
        return AppColors.statusSubmitted;
      case NotificationType.adminResponse:
        return AppColors.primary;
      case NotificationType.reportResolved:
        return AppColors.success;
      case NotificationType.reportRejected:
        return AppColors.error;
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}