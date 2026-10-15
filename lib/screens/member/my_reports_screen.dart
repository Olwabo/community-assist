import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../widgets/report_list_tile.dart';
import 'report/report_details_screen.dart';

enum ReportFilter { all, active, resolved }

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final _auth = AuthService();
  final _reportService = ReportService();

  ReportFilter _filter = ReportFilter.all;

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
            title: const Text('My Reports'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildFilterTabs(),
                Expanded(child: _buildList(user.uid)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _tab('All', ReportFilter.all),
          const SizedBox(width: 8),
          _tab('Active', ReportFilter.active),
          const SizedBox(width: 8),
          _tab('Resolved', ReportFilter.resolved),
        ],
      ),
    );
  }

  Widget _tab(String label, ReportFilter filter) {
    final isSelected = _filter == filter;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _filter = filter),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(String uid) {
    return StreamBuilder<List<ReportModel>>(
      stream: _reportService.streamUserReports(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading reports: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        final all = snapshot.data ?? const <ReportModel>[];
        final filtered = _applyFilter(all);

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = filtered[i];
            return ReportListTile(
              report: r,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportDetailsScreen(reportId: r.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<ReportModel> _applyFilter(List<ReportModel> reports) {
    switch (_filter) {
      case ReportFilter.all:
        return reports;
      case ReportFilter.active:
        return reports
            .where((r) =>
                r.status == ReportStatus.submitted ||
                r.status == ReportStatus.underReview ||
                r.status == ReportStatus.inProgress)
            .toList();
      case ReportFilter.resolved:
        return reports
            .where((r) =>
                r.status == ReportStatus.verified ||
                r.status == ReportStatus.rejected)
            .toList();
    }
  }

  Widget _buildEmptyState() {
    final message = _filter == ReportFilter.all
        ? "You haven't submitted any reports yet"
        : _filter == ReportFilter.active
            ? 'No active reports'
            : 'No resolved reports';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}