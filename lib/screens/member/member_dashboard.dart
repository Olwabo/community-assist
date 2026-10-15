import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../widgets/dashboard_tile.dart';
import '../../widgets/report_list_tile.dart';
import '../auth/login_screen.dart';
import '../../models/report_draft.dart';
import 'report/report_category_screen.dart';
import 'my_reports_screen.dart';
import 'report/report_details_screen.dart';
import 'notifications_screen.dart';
import '../../services/notification_service.dart';
import 'profile_screen.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final _auth = AuthService();
  final _reportService = ReportService();

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _auth.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.streamCurrentUser(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userSnap.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.appName),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: _logout,
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async =>
                  Future.delayed(const Duration(milliseconds: 600)),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildGreeting(user),
                  const SizedBox(height: 24),
                  _buildStats(user.uid),
                  const SizedBox(height: 24),
                  _buildTiles(user.uid),
                  const SizedBox(height: 28),
                  _buildRecentReports(user.uid),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${user.firstName} 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Report community issues. Track their progress.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStats(String uid) {
    return StreamBuilder<List<ReportModel>>(
      stream: _reportService.streamUserReports(uid),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? const <ReportModel>[];
        final total = reports.length;
        final active = reports.where((r) => r.isActive).length;
        final resolved = reports.where((r) => r.isResolved).length;

        return Row(
          children: [
            Expanded(
              child: _statCard('Total', total, AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Active', active, AppColors.statusInProgress),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Resolved', resolved, AppColors.success),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiles(String uid) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        DashboardTile(
          label: 'Report an Issue',
          subtitle: 'Submit a new problem',
          icon: Icons.add_alert,
          color: AppColors.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportCategoryScreen(draft: ReportDraft()),
              ),
            );
          },
        ),
        DashboardTile(
          label: 'My Reports',
          subtitle: 'View & track your reports',
          icon: Icons.list_alt,
          color: AppColors.accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyReportsScreen(),
              ),
            );
          },
        ),
        StreamBuilder<int>(
          stream: NotificationService().streamUnreadCount(uid),
          builder: (context, snapshot) {
            final unread = snapshot.data ?? 0;
            return DashboardTile(
              label: 'Notifications',
              subtitle: unread > 0
                  ? '$unread unread update${unread == 1 ? '' : 's'}'
                  : 'Updates on your reports',
              icon: Icons.notifications_none,
              color: AppColors.statusInProgress,
              badgeCount: unread > 0 ? unread : null,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            );
          },
        ),
          DashboardTile(
          label: 'Profile',
          subtitle: 'Manage your account',
          icon: Icons.person_outline,
          color: AppColors.statusResolved,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentReports(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Reports',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ReportModel>>(
          stream: _reportService.streamUserReports(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final reports = (snapshot.data ?? const <ReportModel>[])
                .take(3)
                .toList();

            if (reports.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 40,
                      color: AppColors.textHint.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "You haven't submitted any reports yet",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "Report an Issue" to get started.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: reports
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                                            child: ReportListTile(
                        report: r,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportDetailsScreen(reportId: r.id),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}