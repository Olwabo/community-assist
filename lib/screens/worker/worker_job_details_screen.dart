import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_categories.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/report_service.dart';
import '../../utils/snackbar.dart';
import '../../widgets/location_map.dart';
import '../../widgets/status_badge.dart';
import 'submit_repair_screen.dart';
import '../../models/notification_model.dart';

class WorkerJobDetailsScreen extends StatefulWidget {
  final String reportId;

  const WorkerJobDetailsScreen({super.key, required this.reportId});

  @override
  State<WorkerJobDetailsScreen> createState() =>
      _WorkerJobDetailsScreenState();
}

class _WorkerJobDetailsScreenState extends State<WorkerJobDetailsScreen> {
  final _auth = AuthService();
  final _reportService = ReportService();
  final _notificationService = NotificationService();

  bool _isMarking = false;

  Future<void> _markInProgress(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Job?'),
        content: const Text(
          'This will mark the report as In Progress. '
          'The admin and reporter will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final workerUid = _auth.currentUid;
    if (workerUid == null) return;

    setState(() => _isMarking = true);

    try {
      await _reportService.markInProgress(
        reportId: report.id,
        workerUid: workerUid,
      );

      // Notify admin + reporter
      await _notifyStatusChange(
        report: report,
        newStatus: ReportStatus.inProgress,
        notifBody: '${report.reportNumber} is now being worked on.',
      );

      if (!mounted) return;
      AppSnackbar.success(context, 'Job marked as In Progress');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  Future<void> _notifyStatusChange({
    required ReportModel report,
    required ReportStatus newStatus,
    required String notifBody,
  }) async {
    // Notify the reporter
    await _notificationService.createNotification(
      userId: report.userId,
      title: 'Report ${newStatus.label}',
      body: notifBody,
      type: NotificationType.statusChange,
      reportId: report.id,
      reportNumber: report.reportNumber,
      data: {'newStatus': newStatus.key},
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReportModel?>(
      stream: _reportService.streamReport(widget.reportId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final report = snapshot.data;
        if (report == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Job')),
            body: const Center(child: Text('Report not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(report.reportNumber),
            backgroundColor: const Color(0xFF14B8A6),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPhoto(report),
                const SizedBox(height: 16),
                StatusBadge(status: report.status),
                const SizedBox(height: 20),
                _buildCategoryCard(report),
                const SizedBox(height: 16),
                _buildDescriptionCard(report),
                const SizedBox(height: 16),
                _buildLocationCard(report),
                const SizedBox(height: 16),
                _buildReporterCard(report),
                const SizedBox(height: 24),
                _buildActionButtons(report),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoto(ReportModel report) {
    Uint8List? bytes;
    if (report.photoBase64 != null && report.photoBase64!.isNotEmpty) {
      try {
        bytes = base64Decode(report.photoBase64!);
      } catch (_) {}
    }

    if (bytes == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: AppColors.textHint,
              ),
              SizedBox(height: 8),
              Text(
                'No photo attached',
                style: TextStyle(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        bytes,
        width: double.infinity,
        height: 260,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCategoryCard(ReportModel report) {
    return _card(
      'Category',
      Row(
        children: [
          Icon(report.category.icon, color: const Color(0xFF14B8A6), size: 22),
          const SizedBox(width: 10),
          Text(
            report.category.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ReportModel report) {
    return _card(
      'Description',
      Text(
        report.description,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLocationCard(ReportModel report) {
    return _card(
      'Location',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationMap(
            location: report.location,
            height: 180,
            interactive: true,
          ),
          const SizedBox(height: 10),
          Text(
            '${report.location.latitude.toStringAsFixed(5)}, '
            '${report.location.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterCard(ReportModel report) {
    return _card(
      'Reported By',
      Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                report.userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.userEmail,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Reported ${DateFormat('d MMM yyyy').format(report.createdAt)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ReportModel report) {
    if (report.status == ReportStatus.assigned) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isMarking ? null : () => _markInProgress(report),
          icon: _isMarking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_arrow),
          label: const Text('Mark In Progress'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusInProgress,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (report.status == ReportStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SubmitRepairScreen(report: report),
              ),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Submit Repair Evidence'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF14B8A6),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (report.status == ReportStatus.repaired) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.statusUnderReview.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.statusUnderReview.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.hourglass_top,
              color: AppColors.statusUnderReview,
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Waiting for verification by admin or reporter.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.statusUnderReview,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (report.status == ReportStatus.verified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.success, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Job verified and closed.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (report.status == ReportStatus.disputed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.error,
                  size: 22,
                ),
                SizedBox(width: 12),
                Text(
                  'Reporter disputed the repair',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            if (report.disputeReason != null &&
                report.disputeReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${report.disputeReason}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'Awaiting admin reassignment.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}