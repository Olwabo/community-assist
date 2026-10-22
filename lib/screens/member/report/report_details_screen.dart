import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_statuses.dart';
import '../../../models/notification_model.dart';
import '../../../models/report_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/report_service.dart';
import '../../../utils/snackbar.dart';
import '../../../widgets/location_map.dart';
import '../../../widgets/status_badge.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
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
            appBar: AppBar(title: const Text('Report Details')),
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
                  Clipboard.setData(
                    ClipboardData(text: report.reportNumber),
                  );
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
                _buildStatusHeader(report),
                const SizedBox(height: 24),
                _buildCategorySection(report),
                const SizedBox(height: 16),
                _buildDescriptionSection(report),
                const SizedBox(height: 16),
                _buildLocationSection(report),
                const SizedBox(height: 16),

                // Repair evidence (only if worker has submitted it)
                if (report.hasRepairEvidence) ...[
                  _buildRepairEvidenceSection(report),
                  const SizedBox(height: 16),
                ],

                _buildTimelineSection(report),

                if (report.adminResponse != null &&
                    report.adminResponse!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAdminResponse(report),
                ],

                const SizedBox(height: 16),
                _buildMetaSection(report),
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
                size: 44,
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
  // STATUS HEADER
  // ============================================================

  Widget _buildStatusHeader(ReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(status: report.status),
            const Spacer(),
            Text(
              _formatDate(report.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        
        // NEW: Show who is working on it
        if (report.assignedToName != null &&
            report.status != ReportStatus.verified &&
            report.status != ReportStatus.rejected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.handyman_outlined,
                  size: 14,
                  color: Color(0xFF14B8A6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Worker: ${report.assignedToName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F766E),
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
  // SECTIONS
  // ============================================================

  Widget _buildCategorySection(ReportModel report) {
    return _card(
      'Category',
      Row(
        children: [
          Icon(report.category.icon, color: AppColors.primary, size: 22),
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

  Widget _buildDescriptionSection(ReportModel report) {
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

  Widget _buildLocationSection(ReportModel report) {
    return _card(
      'Location',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationMap(
            location: report.location,
            height: 180,
            interactive: false,
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

  // ============================================================
  // REPAIR EVIDENCE
  // ============================================================

  Widget _buildRepairEvidenceSection(ReportModel report) {
    Uint8List? repairBytes;
    if (report.repairPhotoBase64 != null &&
        report.repairPhotoBase64!.isNotEmpty) {
      try {
        repairBytes = base64Decode(report.repairPhotoBase64!);
      } catch (_) {}
    }

    // Distance between original and repair location
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

    // Can the current user verify/dispute?
    final currentUid = _auth.currentUid;
    final canVerifyOrDispute = report.status == ReportStatus.repaired &&
        currentUid != null &&
        report.userId == currentUid;

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

          // Action buttons (only for reporter of a repaired report)
          if (canVerifyOrDispute) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 10),
            const Text(
              'Is the issue fixed?',
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
                    label: const Text('Still Broken'),
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
                    label: const Text('Verify Fixed'),
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

          // Already verified
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

          // Already disputed
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
                        'Repair was disputed.',
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
  // VERIFY / DISPUTE ACTIONS
  // ============================================================

  Future<void> _verifyRepair(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Repair'),
        content: const Text(
          'Is the problem resolved to your satisfaction?\n\n'
          'Once verified, this report will be closed.',
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
      );

      // Notify the worker if there was one
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
      AppSnackbar.success(context, 'Thank you for verifying!');
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
        title: const Text('Report as Still Broken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell the admin what still needs fixing:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. The pothole is still there, just smaller.',
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
                    content: Text('Please describe what is still wrong'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Submit'),
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

      if (!mounted) return;
      AppSnackbar.info(context, 'Report sent back to admin');
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
    if (report.statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final history = [...report.statusHistory]
      ..sort((a, b) => b.changedAt.compareTo(a.changedAt));

    return _card(
      'Status Timeline',
      Column(
        children: history.asMap().entries.map((entry) {
          final idx = entry.key;
          final change = entry.value;
          final isLast = idx == history.length - 1;
          return _timelineRow(change, isLast);
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
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: change.status.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: change.status.color.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        change.status.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: change.status.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(change.changedAt),
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
                        fontSize: 13,
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
  // ADMIN RESPONSE
  // ============================================================

  Widget _buildAdminResponse(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
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
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // META
  // ============================================================

  Widget _buildMetaSection(ReportModel report) {
    final currentUid = _auth.currentUid;
    final isOwnReport = report.userId == currentUid;
    
    return _card(
      'Report Details',
      Column(
        children: [
          _metaRow('Reference', report.reportNumber),
          const SizedBox(height: 8),
          _metaRow('Submitted', _formatDate(report.createdAt)),
          const SizedBox(height: 8),
          _metaRow('Last updated', _formatDate(report.updatedAt)),
          
          // ONLY show the reporter's name/email if they are looking at their OWN report
          if (isOwnReport) ...[
            const Divider(height: 24),
            _metaRow('Submitted by', report.userName),
            const SizedBox(height: 8),
            _metaRow('Email', report.userEmail),
          ] else ...[
             const Divider(height: 24),
             const Row(
               children: [
                 Icon(Icons.lock_outline, size: 14, color: AppColors.textHint),
                 SizedBox(width: 8),
                 Text(
                   'Reporter details are private',
                   style: TextStyle(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic),
                 ),
               ],
             )
          ]
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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

  String _formatDate(DateTime dt) {
    return DateFormat('d MMM yyyy • HH:mm').format(dt);
  }
}