import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../widgets/admin_report_list_tile.dart';
import 'report_admin_view_screen.dart';

class ReportManagementScreen extends StatefulWidget {
  final ReportStatus? initialFilter;

  const ReportManagementScreen({super.key, this.initialFilter});

  @override
  State<ReportManagementScreen> createState() =>
      _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  final _reportService = ReportService();

  /// null = "All" filter
  ReportStatus? _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reports'),
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
            _filterChip('All', null),
            const SizedBox(width: 8),
            // Show only these specific statuses in the filter bar
            ...ReportStatus.values.where((s) => 
              s != ReportStatus.underReview && s != ReportStatus.verified
            ).map((status) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filterChip(status.label, status),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, ReportStatus? status) {
    final isActive = _activeFilter == status;
    final color = status?.color ?? AppColors.primary;

    return Material(
      color: isActive ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _activeFilter = status),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status != null) ...[
                Icon(
                  status.icon,
                  size: 14,
                  color: isActive ? Colors.white : status.color,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<ReportModel>>(
      stream: _reportService.streamAllReports(
        statusFilter: _activeFilter,
      ),
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

        final reports = snapshot.data ?? const <ReportModel>[];

        // If the filter is 'repaired', show both repaired AND verified reports
        final filteredReports = _activeFilter == ReportStatus.repaired
            ? reports.where((r) => r.status == ReportStatus.repaired || r.status == ReportStatus.verified).toList()
            : reports;

        if (filteredReports.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Showing ${filteredReports.length} '
                    'report${filteredReports.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: filteredReports.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r = filteredReports[i];
                  return AdminReportListTile(
                    report: r,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportAdminViewScreen(reportId: r.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final filterText = _activeFilter?.label ?? 'any status';
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
              'No reports with $filterText',
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