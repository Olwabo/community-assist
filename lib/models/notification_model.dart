import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  statusChange,
  adminResponse,
  reportResolved,
  reportRejected,
}

extension NotificationTypeX on NotificationType {
  String get key {
    switch (this) {
      case NotificationType.statusChange:
        return 'status_change';
      case NotificationType.adminResponse:
        return 'admin_response';
      case NotificationType.reportResolved:
        return 'report_resolved';
      case NotificationType.reportRejected:
        return 'report_rejected';
    }
  }

  static NotificationType fromKey(String? key) {
    return NotificationType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => NotificationType.statusChange,
    );
  }
}

class AppNotificationModel {
  final String id;
  final String userId;
  final String? reportId;
  final String? reportNumber;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    this.reportId,
    this.reportNumber,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  //Firestore

  factory AppNotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return AppNotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      reportId: map['reportId'] as String?,
      reportNumber: map['reportNumber'] as String?,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationTypeX.fromKey(map['type'] as String?),
      data: Map<String, dynamic>.from(map['data'] ?? const {}),
      isRead: map['isRead'] ?? false,
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'reportId': reportId,
      'reportNumber': reportNumber,
      'title': title,
      'body': body,
      'type': type.key,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotificationModel copyWith({
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id,
      userId: userId,
      reportId: reportId,
      reportNumber: reportNumber,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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