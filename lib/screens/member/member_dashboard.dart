import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../widgets/dashboard_tile.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/report_list_tile.dart';
import '../auth/login_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'report/report_category_screen.dart';
import 'report/report_details_screen.dart';
import 'community_feed_screen.dart';
import '../../models/report_draft.dart';
import '../../services/notification_service.dart';

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
              // Real-time Notification Bell
              StreamBuilder<int>(
                stream: NotificationService().streamUnreadCount(user.uid),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return NotificationBell(
                    unreadCount: unread,
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
              // Profile Icon
              IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: 'Profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              // Logout (Hidden in a menu to keep the AppBar clean)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') _logout();
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ];
                },
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
                  const SizedBox(height: 28),
                  
                  // Section Header
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildPrimaryAction(user.uid),
                  const SizedBox(height: 12),
                  
                  // Two smaller tiles side-by-side
                  Row(
                    children: [
                      Expanded(
                        child: DashboardTile(
                          label: 'My Reports',
                          subtitle: 'Track your issues',
                          icon: Icons.fact_check_outlined,
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyReportsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardTile(
                          label: 'Community',
                          subtitle: 'See others issues',
                          icon: Icons.map_outlined,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CommunityFeedScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
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
          'Hello, ${user.firstName}', // Removed the emoji
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Help keep KuGompo Metro running smoothly.',
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
              child: _statCard('Active', active, AppColors.warning),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(String uid) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportCategoryScreen(draft: ReportDraft()),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_alert_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report an Issue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Spot a pothole or broken light? Let us know.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReports(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
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
                child: const Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "You haven't submitted any reports yet",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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