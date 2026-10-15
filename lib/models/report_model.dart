import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_categories.dart';
import '../constants/app_statuses.dart';

class ReportLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;

  const ReportLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
  });

  factory ReportLocation.fromMap(Map<String, dynamic> map) {
    return ReportLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'address': address,
    };
  }
}

class StatusChange {
  final ReportStatus status;
  final DateTime changedAt;
  final String changedBy;
  final String? note;

  const StatusChange({
    required this.status,
    required this.changedAt,
    required this.changedBy,
    this.note,
  });

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      status: ReportStatusX.fromKey(map['status'] as String? ?? 'submitted'),
      changedAt: _toDate(map['changedAt']),
      changedBy: map['changedBy'] ?? '',
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.key,
      'changedAt': Timestamp.fromDate(changedAt),
      'changedBy': changedBy,
      'note': note,
    };
  }
}

class ReportModel {
  final String id; // Firestore doc ID
  final String reportNumber; // e.g. CA-000123
  final String userId;
  final String userName;
  final String userEmail;

  final ReportCategory category;
  final String description;

  final String? photoUrl;
  final String? photoPath;
  final String? photoBase64; 

  final ReportLocation location;

  final ReportStatus status;
  final List<StatusChange> statusHistory;

  final String? adminResponse;
  final String? assignedTo;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

    // Assignment (worker)
  final String? assignedToName;
  final DateTime? assignedAt;

  // Repair evidence (worker)
  final String? repairPhotoBase64;
  final ReportLocation? repairLocation;
  final String? repairNotes;
  final DateTime? repairedAt;

  // Verification
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final bool disputed;
  final String? disputeReason;

  const ReportModel({
    required this.id,
    required this.reportNumber,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.description,
    this.photoUrl,
    this.photoPath,
    this.photoBase64,  
    required this.location,
    required this.status,
    this.statusHistory = const [],
    this.adminResponse,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.assignedToName,
    this.assignedAt,
    this.repairPhotoBase64,
    this.repairLocation,
    this.repairNotes,
    this.repairedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.disputed = false,
    this.disputeReason,
  });

  bool get isResolved => status == ReportStatus.verified;
  bool get isActive =>
      status != ReportStatus.verified && status != ReportStatus.rejected;
  bool get hasPhoto => photoUrl != null || photoBase64 != null;
  bool get isAssigned => status == ReportStatus.assigned;
  bool get isInProgress => status == ReportStatus.inProgress;
  bool get isRepaired => status == ReportStatus.repaired;
  bool get isVerified => status == ReportStatus.verified;
  bool get isDisputed => status == ReportStatus.disputed;
  bool get hasRepairEvidence =>
      repairPhotoBase64 != null && repairPhotoBase64!.isNotEmpty;

  // ---------- Firestore ----------

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      reportNumber: map['reportNumber'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      category: ReportCategoryX.fromKey(map['category'] as String? ?? 'other'),
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] as String?,
      photoPath: map['photoPath'] as String?,
      photoBase64: map['photoBase64'] as String?,
      location: ReportLocation.fromMap(
        Map<String, dynamic>.from(map['location'] ?? const {}),
      ),
      status: ReportStatusX.fromKey(map['status'] as String? ?? 'submitted'),
      statusHistory: (map['statusHistory'] as List<dynamic>? ?? const [])
          .map((e) => StatusChange.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      adminResponse: map['adminResponse'] as String?,
      assignedTo: map['assignedTo'] as String?,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      resolvedAt: map['resolvedAt'] == null ? null : _toDate(map['resolvedAt']),
      assignedToName: map['assignedToName'] as String?,
      assignedAt: map['assignedAt'] == null
          ? null
          : _toDate(map['assignedAt']),
      repairPhotoBase64: map['repairPhotoBase64'] as String?,
      repairLocation: map['repairLocation'] == null
          ? null
          : ReportLocation.fromMap(
              Map<String, dynamic>.from(map['repairLocation']),
            ),
      repairNotes: map['repairNotes'] as String?,
      repairedAt: map['repairedAt'] == null
          ? null
          : _toDate(map['repairedAt']),
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: map['verifiedAt'] == null
          ? null
          : _toDate(map['verifiedAt']),
      disputed: map['disputed'] ?? false,
      disputeReason: map['disputeReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportNumber': reportNumber,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'category': category.key,
      'categoryLabel': category.label,
      'description': description,
      'photoUrl': photoUrl,
      'photoPath': photoPath,
      'photoBase64': photoBase64, 
      'location': location.toMap(),
      'status': status.key,
      'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
      'adminResponse': adminResponse,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
      'assignedToName': assignedToName,
      'assignedAt': assignedAt == null
          ? null
          : Timestamp.fromDate(assignedAt!),
      'repairPhotoBase64': repairPhotoBase64,
      'repairLocation': repairLocation?.toMap(),
      'repairNotes': repairNotes,
      'repairedAt': repairedAt == null
          ? null
          : Timestamp.fromDate(repairedAt!),
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt == null
          ? null
          : Timestamp.fromDate(verifiedAt!),
      'disputed': disputed,
      'disputeReason': disputeReason,
    };
  }

  ReportModel copyWith({
    String? id,
    String? reportNumber,
    ReportCategory? category,
    String? description,
    String? photoUrl,
    String? photoPath,
    String? photoBase64,
    ReportLocation? location,
    ReportStatus? status,
    List<StatusChange>? statusHistory,
    String? adminResponse,
    String? assignedTo,
    String? assignedToName,
    DateTime? assignedAt,
    String? repairPhotoBase64,
    ReportLocation? repairLocation,
    String? repairNotes,
    DateTime? repairedAt,
    String? verifiedBy,
    DateTime? verifiedAt,
    bool? disputed,
    String? disputeReason,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      category: category ?? this.category,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      photoBase64: photoBase64 ?? this.photoBase64,
      location: location ?? this.location,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      adminResponse: adminResponse ?? this.adminResponse,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedAt: assignedAt ?? this.assignedAt,
      repairPhotoBase64: repairPhotoBase64 ?? this.repairPhotoBase64,
      repairLocation: repairLocation ?? this.repairLocation,
      repairNotes: repairNotes ?? this.repairNotes,
      repairedAt: repairedAt ?? this.repairedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      disputed: disputed ?? this.disputed,
      disputeReason: disputeReason ?? this.disputeReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

// Helper
DateTime _toDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
