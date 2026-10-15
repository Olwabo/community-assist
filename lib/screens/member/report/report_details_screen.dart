import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_statuses.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import '../../../widgets/location_map.dart';
import '../../../widgets/status_badge.dart';

class ReportDetailsScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

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

  Widget _buildStatusHeader(ReportModel report) {
    return Row(
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
    );
  }

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

  Widget _buildTimelineSection(ReportModel report) {
    if (report.statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Reverse so newest is on top
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

  Widget _buildMetaSection(ReportModel report) {
    return _card(
      'Report Details',
      Column(
        children: [
          _metaRow('Submitted by', report.userName),
          const SizedBox(height: 8),
          _metaRow('Email', report.userEmail),
          const SizedBox(height: 8),
          _metaRow('Submitted', _formatDate(report.createdAt)),
          const SizedBox(height: 8),
          _metaRow('Last updated', _formatDate(report.updatedAt)),
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