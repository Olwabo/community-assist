import 'package:flutter/material.dart';
import 'app_colors.dart';

enum ReportStatus {
  submitted,
  underReview,
  assigned,
  inProgress,
  repaired,
  verified,
  disputed,
  rejected,
}

extension ReportStatusX on ReportStatus {
  String get key {
    switch (this) {
      case ReportStatus.submitted:
        return 'submitted';
      case ReportStatus.underReview:
        return 'under_review';
      case ReportStatus.assigned:
        return 'assigned';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.repaired:
        return 'repaired';
      case ReportStatus.verified:
        return 'verified';
      case ReportStatus.disputed:
        return 'disputed';
      case ReportStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.assigned:
        return 'Assigned';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.repaired:
        return 'Repaired';
      case ReportStatus.verified:
        return 'Verified';
      case ReportStatus.disputed:
        return 'Disputed';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.submitted:
        return AppColors.statusSubmitted;
      case ReportStatus.underReview:
        return AppColors.statusUnderReview;
      case ReportStatus.assigned:
        return const Color(0xFF06B6D4); // cyan
      case ReportStatus.inProgress:
        return AppColors.statusInProgress;
      case ReportStatus.repaired:
        return const Color(0xFF14B8A6); // teal
      case ReportStatus.verified:
        return AppColors.success;
      case ReportStatus.disputed:
        return AppColors.error;
      case ReportStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.submitted:
        return Icons.send_outlined;
      case ReportStatus.underReview:
        return Icons.hourglass_top;
      case ReportStatus.assigned:
        return Icons.assignment_ind_outlined;
      case ReportStatus.inProgress:
        return Icons.engineering_outlined;
      case ReportStatus.repaired:
        return Icons.handyman_outlined;
      case ReportStatus.verified:
        return Icons.verified_outlined;
      case ReportStatus.disputed:
        return Icons.report_problem_outlined;
      case ReportStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  static ReportStatus fromKey(String? key) {
    if (key == null || key.isEmpty) return ReportStatus.submitted;
    return ReportStatus.values.firstWhere(
      (s) => s.key == key,
      orElse: () => ReportStatus.submitted,
    );
  }
}