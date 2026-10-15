import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_categories.dart';
import '../constants/app_statuses.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  // ---------------- Counter / reference number ----------------

  /// Atomically generates the next report number: CA-000124, etc.
  Future<String> _generateReportNumber() async {
    final counterRef = _db.collection('reportCounters').doc('global');

    return _db.runTransaction((tx) async {
      final snap = await tx.get(counterRef);

      int current = 0;
      String prefix = 'CA';
      int padding = 6;

      if (snap.exists) {
        final data = snap.data()!;
        current = (data['currentValue'] ?? 0) as int;
        prefix = (data['prefix'] ?? 'CA') as String;
        padding = (data['padding'] ?? 6) as int;
      }

      final next = current + 1;

      tx.set(
        counterRef,
        {
          'currentValue': next,
          'prefix': prefix,
          'padding': padding,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return '$prefix-${next.toString().padLeft(padding, '0')}';
    });
  }

  // ---------------- Create ----------------

  /// Submit a new report. Returns the created ReportModel with id + reportNumber.
  Future<ReportModel> submitReport({
    required String userId,
    required String userName,
    required String userEmail,
    required ReportCategory category,
    required String description,
    required ReportLocation location,
    String? photoUrl,
    String? photoPath,
    String? photoBase64,  
  }) async {
    final reportNumber = await _generateReportNumber();
    final now = DateTime.now();

    // Build initial status history entry
    final initialHistory = [
      StatusChange(
        status: ReportStatus.submitted,
        changedAt: now,
        changedBy: userId,
        note: 'Report submitted',
      ),
    ];

    final report = ReportModel(
      id: '', // placeholder — set after doc creation
      reportNumber: reportNumber,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      category: category,
      description: description,
      photoUrl: photoUrl,
      photoPath: photoPath,
      photoBase64: photoBase64,
      location: location,
      status: ReportStatus.submitted,
      statusHistory: initialHistory,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = _reports.doc();
    await docRef.set(report.toMap());

    // Return with the generated Firestore ID
    return report.copyWith(id: docRef.id);
  }

  // ---------------- Read ----------------

  /// Stream all reports for the given user, newest first.
  Stream<List<ReportModel>> streamUserReports(String userId) {
    return _reports
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream all reports (admin view), newest first.
  Stream<List<ReportModel>> streamAllReports({ReportStatus? statusFilter}) {
    Query<Map<String, dynamic>> q = _reports;
    if (statusFilter != null) {
      q = q.where('status', isEqualTo: statusFilter.key);
    }
    return q.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => ReportModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Fetch a single report once.
  Future<ReportModel?> getReport(String reportId) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReportModel.fromMap(doc.id, doc.data()!);
  }

  /// Stream a single report (for live updates on detail screen).
  Stream<ReportModel?> streamReport(String reportId) {
    return _reports.doc(reportId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ReportModel.fromMap(snap.id, snap.data()!);
    });
  }

  // ---------------- Update (admin) ----------------

  /// Admin changes status / provides a response.
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    required String adminUid,
    String? adminResponse,
    String? note,
  }) async {
    final now = DateTime.now();

    final update = <String, dynamic>{
      'status': newStatus.key,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([
        StatusChange(
          status: newStatus,
          changedAt: now,
          changedBy: adminUid,
          note: note,
        ).toMap(),
      ]),
    };

    if (adminResponse != null && adminResponse.trim().isNotEmpty) {
      update['adminResponse'] = adminResponse.trim();
    }

    if (newStatus == ReportStatus.verified) {
      update['resolvedAt'] = Timestamp.fromDate(now);
    }

    await _reports.doc(reportId).update(update);
  }

  // ---------------- Dashboard counts (admin) ----------------

  Future<Map<String, int>> getStatusCounts() async {
    final counts = <String, int>{};
    for (final status in ReportStatus.values) {
      final snap = await _reports
          .where('status', isEqualTo: status.key)
          .count()
          .get();
      counts[status.key] = snap.count ?? 0;
    }
    return counts;
  }
    /// Stream all reports and derive status counts client-side.
  /// Simpler than 5 parallel count queries, and updates live.
  Stream<Map<ReportStatus, int>> streamStatusCounts() {
    return _reports.snapshots().map((snap) {
      final counts = <ReportStatus, int>{
        for (final s in ReportStatus.values) s: 0,
      };
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = ReportStatusX.fromKey(data['status'] as String?);
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    });
  }
}