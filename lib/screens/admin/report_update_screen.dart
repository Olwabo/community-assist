import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/notification_model.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/report_service.dart';
import '../../utils/snackbar.dart';
import '../../widgets/primary_button.dart';

class ReportUpdateScreen extends StatefulWidget {
  final ReportModel report;

  const ReportUpdateScreen({super.key, required this.report});

  @override
  State<ReportUpdateScreen> createState() => _ReportUpdateScreenState();
}

class _ReportUpdateScreenState extends State<ReportUpdateScreen> {
  final _auth = AuthService();
  final _reportService = ReportService();
  final _notificationService = NotificationService();

  final _noteCtrl = TextEditingController();
  final _responseCtrl = TextEditingController();

  late ReportStatus _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _responseCtrl.text = widget.report.adminResponse ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validation
    if (_selectedStatus == widget.report.status &&
        _responseCtrl.text.trim().isEmpty &&
        _noteCtrl.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Change something before saving');
      return;
    }

    final adminUid = _auth.currentUid;
    if (adminUid == null) {
      AppSnackbar.error(context, 'Not authenticated');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final statusChanged = _selectedStatus != widget.report.status;
      final responseText = _responseCtrl.text.trim();

      // 1. Update Firestore
      await _reportService.updateReportStatus(
        reportId: widget.report.id,
        newStatus: _selectedStatus,
        adminUid: adminUid,
        adminResponse: responseText.isNotEmpty ? responseText : null,
        note: _noteCtrl.text.trim().isNotEmpty
            ? _noteCtrl.text.trim()
            : null,
      );

      // 2. Create notification for the reporter
      if (statusChanged || responseText.isNotEmpty) {
        final title = statusChanged
            ? 'Report ${_selectedStatus.label}'
            : 'Admin Response Added';

        final body = statusChanged
            ? 'Your report ${widget.report.reportNumber} '
                'is now ${_selectedStatus.label}.'
            : 'The admin has responded to ${widget.report.reportNumber}.';

        await _notificationService.createNotification(
          userId: widget.report.userId,
          title: title,
          body: body,
          type: _selectedStatus == ReportStatus.verified
              ? NotificationType.reportResolved
              : _selectedStatus == ReportStatus.rejected
                  ? NotificationType.reportRejected
                  : statusChanged
                      ? NotificationType.statusChange
                      : NotificationType.adminResponse,
          reportId: widget.report.id,
          reportNumber: widget.report.reportNumber,
          data: {
            'oldStatus': widget.report.status.key,
            'newStatus': _selectedStatus.key,
          },
        );
      }

      if (!mounted) return;
      AppSnackbar.success(context, 'Report updated');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Update failed: $e');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Report')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reference
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.report.reportNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'New Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...ReportStatus.values.map(
                      (status) => _statusOption(status),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Internal note — not shown to the reporter.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Assigned to roads department',
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Admin Response',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This message will be shown to the reporter.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _responseCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Site visit scheduled. Will update once complete.',
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: PrimaryButton(
                label: 'Save Update',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(ReportStatus status) {
    final isSelected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedStatus = status),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? status.color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? status.color
                          : AppColors.textHint,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    status.icon,
                    size: 18,
                    color: status.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (widget.report.status == status)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}