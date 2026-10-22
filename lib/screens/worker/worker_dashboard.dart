import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_categories.dart'; // Needed for category icons
import '../../constants/app_statuses.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../auth/login_screen.dart';
import '../member/profile_screen.dart';
import 'worker_report_list_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
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
            title: const Text('Worker Portal'),
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
                  _buildStats(user.uid),
                  const SizedBox(height: 28),
                  _buildActionCard(user.uid),
                  const SizedBox(height: 28),
                  _buildAssignedList(user.uid),
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
          'Hello, ${user.firstName}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here are your assigned maintenance jobs.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(String uid) {
    return StreamBuilder<List<ReportModel>>(
      stream: _reportService.streamAssignedReports(uid),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? const <ReportModel>[];
        
        final assigned = reports
            .where((r) => r.status == ReportStatus.assigned)
            .length;
            
        final working = reports
            .where((r) => r.status == ReportStatus.inProgress)
            .length;
            
        final done = reports
            .where((r) => r.status == ReportStatus.repaired || r.status == ReportStatus.verified)
            .length;

        return Row(
          children: [
            Expanded(
              child: _statCard('Assigned', assigned, const Color(0xFF06B6D4)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Working', working, AppColors.statusInProgress),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Done', done, const Color(0xFF14B8A6)),
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

  Widget _buildActionCard(String uid) {
    return Material(
      color: const Color(0xFF14B8A6), // Teal
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkerReportListScreen(workerId: uid),
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
                  Icons.list_alt,
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
                      'My Jobs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View all assigned reports and start working.',
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

  Widget _buildAssignedList(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Assignments',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ReportModel>>(
          stream: _reportService.streamAssignedReports(uid),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No jobs assigned yet',
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
                      child: _AssignedTile(
                        report: r,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkerReportListScreen(workerId: uid),
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

class _AssignedTile extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _AssignedTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  report.category.icon,
                  color: const Color(0xFF14B8A6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reportNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: report.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: report.status.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}