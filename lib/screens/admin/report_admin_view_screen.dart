import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/app_categories.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_statuses.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../widgets/location_map.dart';
import '../../widgets/status_badge.dart';
import 'report_update_screen.dart';

class ReportAdminViewScreen extends StatelessWidget {
  final String reportId;

  const ReportAdminViewScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final service = ReportService();

    return StreamBuilder<ReportModel?>(
      stream: service.streamReport(reportId),
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

  Widget _buildStatusHeader(BuildContext context, ReportModel report) {
    return Row(
      children: [
        StatusBadge(status: report.status),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportUpdateScreen(report: report),
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Update'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            minimumSize: const Size(0, 0),
          ),
        ),
      ],
    );
  }

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
}
