import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_categories.dart';
import '../constants/app_statuses.dart';
import '../models/report_model.dart';
import 'package:geolocator/geolocator.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');


  // Atomically generates the next report number: CA-000124, etc.
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

  // Submit a new report. Returns the created ReportModel with id + reportNumber.
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

  // Stream all reports, newest first.
  Stream<List<ReportModel>> streamAllReports({ReportStatus? statusFilter}) {
    Query<Map<String, dynamic>> q = _reports;
    
    // If the admin selects "Repaired", we don't filter by status in Firestore.
    // Instead, we fetch everything and let the UI filter (Repaired + Verified).
    if (statusFilter != null && statusFilter != ReportStatus.repaired) {
      q = q.where('status', isEqualTo: statusFilter.key);
    }

    return q.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final reports = snap.docs
          .map((d) => ReportModel.fromMap(d.id, d.data()))
          .toList();

      // Apply local filter for Repaired to include Verified
      if (statusFilter == ReportStatus.repaired) {
        return reports.where((r) => 
          r.status == ReportStatus.repaired || r.status == ReportStatus.verified
        ).toList();
      }

      return reports;
    });
  }
    // Stream reports assigned to a specific worker, newest first.
  Stream<List<ReportModel>> streamAssignedReports(String workerId) {
    return _reports
        .where('assignedTo', isEqualTo: workerId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportModel.fromMap(d.id, d.data()))
            .toList());
  }
  // Fetch a single report once.
  Future<ReportModel?> getReport(String reportId) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReportModel.fromMap(doc.id, doc.data()!);
  }

  // Stream a single report (for live updates on detail screen).
  Stream<ReportModel?> streamReport(String reportId) {
    return _reports.doc(reportId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ReportModel.fromMap(snap.id, snap.data()!);
    });
  }


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

  // Dashboard counts

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
    // Stream all reports and derive status counts client-side.
  // Simpler than 5 parallel count queries, and updates live.
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
    // Assign a report to a worker. Sets assignedTo / assignedToName / assignedAt,
  // updates the status to 'assigned', and appends to status history.
  Future<void> assignReportToWorker({
    required String reportId,
    required String workerId,
    required String workerName,
    required String adminUid,
    String? note,
  }) async {
    final now = DateTime.now();

    await _reports.doc(reportId).update({
      'status': ReportStatus.assigned.key,
      'assignedTo': workerId,
      'assignedToName': workerName,
      'assignedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([
        StatusChange(
          status: ReportStatus.assigned,
          changedAt: now,
          changedBy: adminUid,
          note: note ?? 'Assigned to $workerName',
        ).toMap(),
      ]),
    });
  }
    // Worker marks a job as in progress.
  Future<void> markInProgress({
    required String reportId,
    required String workerUid,
    String? note,
  }) async {
    final now = DateTime.now();

    await _reports.doc(reportId).update({
      'status': ReportStatus.inProgress.key,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([
        StatusChange(
          status: ReportStatus.inProgress,
          changedAt: now,
          changedBy: workerUid,
          note: note ?? 'Worker started the repair',
        ).toMap(),
      ]),
    });
  }

  // Worker submits repair evidence → status becomes 'repaired'.
  Future<void> submitRepairEvidence({
    required String reportId,
    required String workerUid,
    required ReportLocation repairLocation,
    required String repairNotes,
    required String repairPhotoBase64,
  }) async {
    final now = DateTime.now();

    await _reports.doc(reportId).update({
      'status': ReportStatus.repaired.key,
      'repairPhotoBase64': repairPhotoBase64,
      'repairLocation': repairLocation.toMap(),
      'repairNotes': repairNotes,
      'repairedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([
        StatusChange(
          status: ReportStatus.repaired,
          changedAt: now,
          changedBy: workerUid,
          note: 'Repair evidence submitted',
        ).toMap(),
      ]),
    });
  }
    // Reporter or admin verifies a completed repair.
  Future<void> verifyRepair({
    required String reportId,
    required String verifierUid,
    String? note,
  }) async {
    final now = DateTime.now();

    await _reports.doc(reportId).update({
      'status': ReportStatus.verified.key,
      'verifiedBy': verifierUid,
      'verifiedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([
        StatusChange(
          status: ReportStatus.verified,
          changedAt: now,
          changedBy: verifierUid,
          note: note ?? 'Repair verified',
        ).toMap(),
      ]),
    });
  }

  // Reporter disputes a repair (still broken / not fixed properly).
  Future<void> disputeRepair({
    required String reportId,
    required String reporterUid,
    required String reason,
  }) async {
    final now = DateTime.now();

    await _reports.doc(reportId).update({
      'status': ReportStatus.disputed.key,
      'disputed': true,
      'disputeReason': reason,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([
        StatusChange(
          status: ReportStatus.disputed,
          changedAt: now,
          changedBy: reporterUid,
          note: 'Reporter disputed: $reason',
        ).toMap(),
      ]),
    });
  }
    // Stream all reports in the community (for the feed).
  // Newest first, excludes the current user's own reports if [excludeUid] is provided.
  Stream<List<ReportModel>> streamCommunityReports({String? excludeUid}) {
    Query<Map<String, dynamic>> q = _reports.orderBy(
      'createdAt',
      descending: true,
    );

    return q.snapshots().map((snap) {
      final reports = snap.docs
          .map((d) => ReportModel.fromMap(d.id, d.data()))
          .toList();

      if (excludeUid == null) return reports;
      return reports.where((r) => r.userId != excludeUid).toList();
    });
  }
    // Checks if there is an active report of the same category within 100 meters.
  Future<ReportModel?> findDuplicateReport({
    required ReportCategory category,
    required ReportLocation location,
  }) async {
    try {
      // Fetch open reports of the same category
      final snap = await _reports
          .where('category', isEqualTo: category.key)
          .where('status', whereIn: [
            ReportStatus.submitted.key,
            ReportStatus.underReview.key,
            ReportStatus.assigned.key,
            ReportStatus.inProgress.key,
            ReportStatus.repaired.key,
          ])
          .get();

      // Check distance for each
      for (final doc in snap.docs) {
        final r = ReportModel.fromMap(doc.id, doc.data());
        final distance = Geolocator.distanceBetween(
          r.location.latitude,
          r.location.longitude,
          location.latitude,
          location.longitude,
        );

        // If it's within 100 meters, it's a duplicate
        if (distance <= 100) {
          return r;
        }
      }

      return null; // No duplicates found
    } catch (e) {
      // If the query fails (e.g. missing index), just ignore and allow submission
      return null;
    }
  }
}