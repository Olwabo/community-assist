import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../widgets/report_list_tile.dart';
import '../auth/login_screen.dart';
import 'manage_workers_screen.dart';
import 'report_admin_view_screen.dart';
import 'report_management_screen.dart';
import '../member/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
            title: const Text('Admin Console'),
            actions: [
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
                  _buildOverview(),
                  const SizedBox(height: 28),
                  
                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  
                  const SizedBox(height: 28),
                  
                  // Status Breakdown
                  const Text(
                    'Reports by Status',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusBreakdown(),
                  
                  const SizedBox(height: 28),
                  _buildRecentReports(),
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
          'Welcome, ${user.firstName}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'KuGompo Metro Management Console',
          style: TextStyle(
            fontSize: 14, 
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    return StreamBuilder<Map<ReportStatus, int>>(
      stream: _reportService.streamStatusCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};
        final total = counts.values.fold<int>(0, (sum, v) => sum + v);
        
        final active = (counts[ReportStatus.submitted] ?? 0) +
            (counts[ReportStatus.assigned] ?? 0) +
            (counts[ReportStatus.inProgress] ?? 0) +
            (counts[ReportStatus.repaired] ?? 0) +
            (counts[ReportStatus.disputed] ?? 0);

        final closed = (counts[ReportStatus.verified] ?? 0) +
            (counts[ReportStatus.rejected] ?? 0);

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
              child: _statCard('Closed', closed, AppColors.success),
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReportManagementScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.folder_open, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All Reports',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageWorkersScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.engineering, color: Color(0xFF14B8A6)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Workers',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown() {
    return StreamBuilder<Map<ReportStatus, int>>(
      stream: _reportService.streamStatusCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};

        final displayStatuses = [
          ReportStatus.submitted,
          ReportStatus.assigned,
          ReportStatus.inProgress,
          ReportStatus.repaired,
          ReportStatus.disputed,
          ReportStatus.rejected,
        ];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: displayStatuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isLast = index == displayStatuses.length - 1;

              int count = counts[status] ?? 0;
              if (status == ReportStatus.repaired) {
                count += counts[ReportStatus.verified] ?? 0;
              }

              return _statusRow(status, count, isLast);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _statusRow(ReportStatus status, int count, bool isLast) {
    final displayLabel = status == ReportStatus.repaired
        ? 'Repaired / Verified'
        : status.label;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportManagementScreen(
              initialFilter: status,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(status.icon, size: 18, color: status.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                displayLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: status.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Reports',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReportManagementScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ReportModel>>(
          stream: _reportService.streamAllReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final reports =
                (snapshot.data ?? const <ReportModel>[]).take(3).toList();

            if (reports.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Text(
                    'No reports submitted yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
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
                              builder: (_) =>
                                  ReportAdminViewScreen(reportId: r.id),
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