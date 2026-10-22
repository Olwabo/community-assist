import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import 'worker_job_details_screen.dart';
import '../../constants/app_categories.dart';

enum _JobFilter { all, assigned, working, repaired }

class WorkerReportListScreen extends StatefulWidget {
  final String workerId;

  const WorkerReportListScreen({super.key, required this.workerId});

  @override
  State<WorkerReportListScreen> createState() =>
      _WorkerReportListScreenState();
}

class _WorkerReportListScreenState extends State<WorkerReportListScreen> {
  final _reportService = ReportService();

  _JobFilter _filter = _JobFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        backgroundColor: const Color(0xFF14B8A6),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _chip('All', _JobFilter.all),
            const SizedBox(width: 8),
            _chip('Assigned', _JobFilter.assigned),
            const SizedBox(width: 8),
            _chip('Working', _JobFilter.working),
            const SizedBox(width: 8),
            _chip('Repaired', _JobFilter.repaired),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _JobFilter filter) {
    final isActive = _filter == filter;
    return Material(
      color: isActive ? const Color(0xFF14B8A6) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF14B8A6)
                  : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<ReportModel>>(
      stream: _reportService.streamAssignedReports(widget.workerId),
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

        final all = snapshot.data ?? const <ReportModel>[];
        final filtered = _applyFilter(all);

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = filtered[i];
            return _JobTile(
              report: r,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkerJobDetailsScreen(reportId: r.id),
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
      case _JobFilter.all:
        return reports;
      case _JobFilter.assigned:
        return reports
            .where((r) => r.status == ReportStatus.assigned)
            .toList();
      case _JobFilter.working:
        return reports
            .where((r) => r.status == ReportStatus.inProgress)
            .toList();
      case _JobFilter.repaired:
        return reports
            .where((r) =>
                r.status == ReportStatus.repaired ||
                r.status == ReportStatus.verified ||
                r.status == ReportStatus.disputed)
            .toList();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman_outlined,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No jobs here',
              style: TextStyle(
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

class _JobTile extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _JobTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      report.category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: report.status.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                report.status.icon,
                                size: 11,
                                color: report.status.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                report.status.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: report.status.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}