import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/report_service.dart';
import '../../utils/snackbar.dart';
import '../../constants/app_categories.dart';
import '../../models/notification_model.dart';

class SelectWorkerScreen extends StatefulWidget {
  final ReportModel report;

  const SelectWorkerScreen({super.key, required this.report});

  @override
  State<SelectWorkerScreen> createState() => _SelectWorkerScreenState();
}

class _SelectWorkerScreenState extends State<SelectWorkerScreen> {
  final _auth = AuthService();
  final _reportService = ReportService();
  final _notificationService = NotificationService();

  String? _assigningTo; // worker uid currently being assigned

  Future<void> _assign(UserModel worker) async {
    final adminUid = _auth.currentUid;
    if (adminUid == null) {
      AppSnackbar.error(context, 'Not authenticated');
      return;
    }

    setState(() => _assigningTo = worker.uid);

    try {
      // Assign in Firestore
      await _reportService.assignReportToWorker(
        reportId: widget.report.id,
        workerId: worker.uid,
        workerName: worker.fullName,
        adminUid: adminUid,
        note: 'Assigned to ${worker.fullName}',
      );

      // Notify the worker
      await _notificationService.createNotification(
        userId: worker.uid,
        title: 'New Job Assigned',
        body: 'You have been assigned ${widget.report.reportNumber} '
            '(${widget.report.category.label}).',
        type: NotificationType.statusChange,
        reportId: widget.report.id,
        reportNumber: widget.report.reportNumber,
        data: {
          'newStatus': 'assigned',
          'category': widget.report.category.key,
        },
      );

      if (!mounted) return;
      AppSnackbar.success(context, 'Assigned to ${worker.fullName}');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigningTo = null);
      AppSnackbar.error(context, 'Failed to assign: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Worker')),
      body: SafeArea(
        child: Column(
          children: [
            // Report info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF14B8A6),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigning ${widget.report.reportNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.report.category.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _auth.streamWorkers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }

                  // Show only active workers
                  final workers = (snapshot.data ?? const <UserModel>[])
                      .where((w) => w.isActive)
                      .toList();

                  if (workers.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: workers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final worker = workers[i];
                      final isAssigning = _assigningTo == worker.uid;
                      return _WorkerOption(
                        worker: worker,
                        isLoading: isAssigning,
                        disabled: _assigningTo != null && !isAssigning,
                        onTap: () => _assign(worker),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
              'No active workers',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add or reactivate a worker from Manage Workers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerOption extends StatelessWidget {
  final UserModel worker;
  final VoidCallback onTap;
  final bool isLoading;
  final bool disabled;

  const _WorkerOption({
    required this.worker,
    required this.onTap,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    worker.initials,
                    style: const TextStyle(
                      color: Color(0xFF14B8A6),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        worker.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF14B8A6),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}