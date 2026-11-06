import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_statuses.dart';

class ReportStatusStepper extends StatelessWidget {
  final ReportStatus currentStatus;

  const ReportStatusStepper({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ReportStatus.submitted,
      ReportStatus.assigned,
      ReportStatus.inProgress,
      ReportStatus.repaired,
      ReportStatus.verified,
    ];

    int currentIndex = steps.indexOf(currentStatus);
    
    final isFailed = currentStatus == ReportStatus.rejected || currentStatus == ReportStatus.disputed;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: isFailed
          ? _buildFailedState(currentStatus)
          : Row(
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;
                final isLast = index == steps.length - 1;

                return Expanded(
                  child: Row(
                    children: [
                      // The Circle
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCompleted ? AppColors.primary : AppColors.divider,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted ? Icons.check : Icons.circle,
                              size: 12,
                              color: isCompleted ? Colors.white : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.label.split(' ').first, // Shorten "Under Review" to "Under"
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCompleted ? AppColors.primary : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      // The Line
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 20), // Align with circles
                            color: index < currentIndex ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildFailedState(ReportStatus status) {
    final isRejected = status == ReportStatus.rejected;
    final color = isRejected ? AppColors.error : AppColors.warning;
    final icon = isRejected ? Icons.cancel : Icons.report_problem;
    final text = isRejected ? 'Report Rejected' : 'Repair Disputed';

    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRejected
                    ? 'This report was invalid or a duplicate.'
                    : 'The reporter marked this repair as incomplete.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}