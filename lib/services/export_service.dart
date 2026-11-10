import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_categories.dart';
import '../constants/app_statuses.dart';
import '../models/report_model.dart';

class ExportService {
  /// Generates a CSV file and triggers the native share/download dialog.
  Future<void> exportReportsToCsv(List<ReportModel> reports) async {
    // 1. Define the headers
    final List<List<dynamic>> rows = [
      [
        'Reference',
        'Date',
        'Category',
        'Description',
        'Reporter',
        'Status',
        'Assigned Worker',
        'Latitude',
        'Longitude',
      ]
    ];

    // 2. Add each report as a row
    for (final r in reports) {
      rows.add([
        r.reportNumber,
        r.createdAt.toIso8601String(),
        r.category.label,
        r.description.replaceAll('\n', ' '),
        r.userName,
        r.status.label,
        r.assignedToName ?? 'Unassigned',
        r.location.latitude,
        r.location.longitude,
      ]);
    }

    // 3. Convert to CSV string
    final csvData = const ListToCsvConverter().convert(rows);

    // 4. Save and Share
    if (kIsWeb) {
      // On Web, we use share_plus to trigger a browser download
      final bytes = utf8.encode(csvData);
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: 'CommunityAssist_Reports.csv')],
        subject: 'CommunityAssist Reports Export',
      );
    } else {
      // On Mobile, we write to a temp file and open the share sheet
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/CommunityAssist_Reports.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'CommunityAssist Reports Export',
      );
    }
  }
}