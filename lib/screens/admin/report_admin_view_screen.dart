import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../constants/app_categories.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/notification_model.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/report_service.dart';
import '../../utils/snackbar.dart';
import '../../widgets/location_map.dart';
import '../../widgets/status_badge.dart';
import 'report_update_screen.dart';
import 'select_worker_screen.dart';

class ReportAdminViewScreen extends StatefulWidget {
  final String reportId;

  const ReportAdminViewScreen({super.key, required this.reportId});

  @override
  State<ReportAdminViewScreen> createState() => _ReportAdminViewScreenState();
}

class _ReportAdminViewScreenState extends State<ReportAdminViewScreen> {
  final _reportService = ReportService();
  final _auth = AuthService();
  final _notificationService = NotificationService();

  bool _isProcessing = false;

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
            appBar: AppBar(title: const Text('Report')),
            body: const Center(child: Text('Report not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(report.reportNumber),
            actions: [
              IconButton(
                tooltip: 'Copy reference',
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: report.reportNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reference number copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPhoto(report),
                const SizedBox(height: 20),
                _buildStatusHeader(context, report),
                const SizedBox(height: 24),
                _buildInfoSection(report),
                const SizedBox(height: 16),
                _buildLocationSection(report),

                // Repair evidence — only if the worker has submitted one
                if (report.hasRepairEvidence) ...[
                  const SizedBox(height: 16),
                  _buildRepairEvidence(report),
                ],

                const SizedBox(height: 16),
                _buildReporterSection(report),
                const SizedBox(height: 16),
                _buildTimelineSection(report),
                if (report.adminResponse != null &&
                    report.adminResponse!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAdminResponseCard(report),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Widget _buildPhoto(ReportModel report) {
    Uint8List? bytes;
    if (report.photoBase64 != null && report.photoBase64!.isNotEmpty) {
      try {
        bytes = base64Decode(report.photoBase64!);
      } catch (_) {}
    }

    if (bytes == null) {
      return Container(
        height: 180,
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

  // ============================================================
  // STATUS HEADER (with Update + Assign)
  // ============================================================

  Widget _buildStatusHeader(BuildContext context, ReportModel report) {
    final canAssign = report.status == ReportStatus.submitted ||
        report.status == ReportStatus.underReview ||
        report.status == ReportStatus.assigned ||
        report.status == ReportStatus.disputed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(status: report.status),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportUpdateScreen(report: report),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Update'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 0),
              ),
            ),
          ],
        ),
        if (canAssign) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SelectWorkerScreen(report: report),
                  ),
                );
                // Screen auto-refreshes via stream
              },
              icon: const Icon(Icons.assignment_ind_outlined),
              label: Text(
                report.assignedToName == null
                    ? 'Assign to Worker'
                    : 'Reassign Worker',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        if (report.assignedToName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.handyman_outlined,
                  size: 18,
                  color: Color(0xFF14B8A6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ASSIGNED TO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.assignedToName!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (report.assignedAt != null)
                  Text(
                    DateFormat('d MMM').format(report.assignedAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // INFO + LOCATION + REPORTER
  // ============================================================

  Widget _buildInfoSection(ReportModel report) {
    return _card(
      'Report Info',
      Column(
        children: [
          _row(
            'Category',
            Row(
              children: [
                Icon(report.category.icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(report.category.label),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _row(
            'Description',
            Text(report.description, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ReportModel report) {
    return _card(
      'Location',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationMap(
            location: report.location,
            height: 160,
            interactive: false,
          ),
          const SizedBox(height: 8),
          Text(
            '${report.location.latitude.toStringAsFixed(5)}, '
            '${report.location.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterSection(ReportModel report) {
    return _card(
      'Reporter',
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
        ],
      ),
    );
  }

  // ============================================================
  // REPAIR EVIDENCE (admin can verify/dispute)
  // ============================================================

  Widget _buildRepairEvidence(ReportModel report) {
    Uint8List? repairBytes;
    if (report.repairPhotoBase64 != null &&
        report.repairPhotoBase64!.isNotEmpty) {
      try {
        repairBytes = base64Decode(report.repairPhotoBase64!);
      } catch (_) {}
    }

    // Distance
    String? distanceText;
    if (report.repairLocation != null) {
      try {
        final distance = Geolocator.distanceBetween(
          report.location.latitude,
          report.location.longitude,
          report.repairLocation!.latitude,
          report.repairLocation!.longitude,
        );
        distanceText = distance < 1000
            ? '${distance.toStringAsFixed(0)} m from original'
            : '${(distance / 1000).toStringAsFixed(1)} km from original';
      } catch (_) {}
    }

    final canVerify = report.status == ReportStatus.repaired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.handyman_outlined,
                size: 20,
                color: Color(0xFF14B8A6),
              ),
              const SizedBox(width: 8),
              const Text(
                'REPAIR EVIDENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Repair photo
          if (repairBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                repairBytes,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),

          // Notes
          if (report.repairNotes != null &&
              report.repairNotes!.isNotEmpty) ...[
            const Text(
              'REPAIR NOTES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              report.repairNotes!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Distance
          if (distanceText != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  distanceText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Repaired at
          if (report.repairedAt != null)
            Text(
              'Repaired ${_formatDate(report.repairedAt!)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),

          // Admin verify/dispute actions
          if (canVerify) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 10),
            const Text(
              'Verify this repair?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _disputeRepair(report),
                    icon: const Icon(
                      Icons.report_problem_outlined,
                      size: 16,
                    ),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _verifyRepair(report),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Already verified feedback
          if (report.status == ReportStatus.verified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'This repair has been verified.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Disputed feedback
          if (report.status == ReportStatus.disputed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        size: 16,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reporter disputed this repair.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (report.disputeReason != null &&
                      report.disputeReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${report.disputeReason}"',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // VERIFY / DISPUTE (admin actions)
  // ============================================================

  Future<void> _verifyRepair(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Repair'),
        content: const Text(
          'Confirm this repair meets the requirements?\n\n'
          'This will close the report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Verify'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = _auth.currentUid;
    if (uid == null) return;

    setState(() => _isProcessing = true);

    try {
      await _reportService.verifyRepair(
        reportId: report.id,
        verifierUid: uid,
        note: 'Verified by admin',
      );

      // Notify reporter
      await _notificationService.createNotification(
        userId: report.userId,
        title: 'Report Verified',
        body: 'Your report ${report.reportNumber} has been resolved.',
        type: NotificationType.reportResolved,
        reportId: report.id,
        reportNumber: report.reportNumber,
      );

      // Notify worker
      if (report.assignedTo != null) {
        await _notificationService.createNotification(
          userId: report.assignedTo!,
          title: 'Repair Verified',
          body: 'Your repair for ${report.reportNumber} was verified.',
          type: NotificationType.reportResolved,
          reportId: report.id,
          reportNumber: report.reportNumber,
        );
      }

      if (!mounted) return;
      AppSnackbar.success(context, 'Repair verified');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _disputeRepair(ReportModel report) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Repair'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why is this repair being rejected?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. Photo does not show the repaired area.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonCtrl.text.trim().length < 5) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please give a reason'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = _auth.currentUid;
    if (uid == null) return;

    setState(() => _isProcessing = true);

    try {
      await _reportService.disputeRepair(
        reportId: report.id,
        reporterUid: uid,
        reason: reasonCtrl.text.trim(),
      );

      // Notify worker
      if (report.assignedTo != null) {
        await _notificationService.createNotification(
          userId: report.assignedTo!,
          title: 'Repair Rejected',
          body: 'Your repair for ${report.reportNumber} was rejected: '
              '${reasonCtrl.text.trim()}',
          type: NotificationType.reportRejected,
          reportId: report.id,
          reportNumber: report.reportNumber,
        );
      }

      if (!mounted) return;
      AppSnackbar.info(context, 'Repair rejected');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Widget _buildTimelineSection(ReportModel report) {
    if (report.statusHistory.isEmpty) return const SizedBox.shrink();

    final history = [...report.statusHistory]
      ..sort((a, b) => b.changedAt.compareTo(a.changedAt));

    return _card(
      'Status Timeline',
      Column(
        children: history.asMap().entries.map((entry) {
          final isLast = entry.key == history.length - 1;
          return _timelineRow(entry.value, isLast);
        }).toList(),
      ),
    );
  }

  Widget _timelineRow(StatusChange change, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: change.status.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.divider)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        change.status.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: change.status.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('d MMM • HH:mm').format(change.changedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  if (change.note != null && change.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      change.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADMIN RESPONSE CARD
  // ============================================================

  Widget _buildAdminResponseCard(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'ADMIN RESPONSE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.adminResponse!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

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

  Widget _row(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            child: value,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('d MMM yyyy • HH:mm').format(dt);
  }
}