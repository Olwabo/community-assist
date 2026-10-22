import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  // Ask the user for notification permission (mostly needed on iOS).
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Get the device FCM token.
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to global topic (used to broadcast to all members).
  Future<void> subscribeToAllReportsTopic() async {
    try {
      await _fcm.subscribeToTopic('all_reports');
    } catch (_) {}
  }

  // Stream notification feed for the given user.
  Stream<List<AppNotificationModel>> streamUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotificationModel.fromMap(d.id, d.data()))
            .toList());
  }

  // Count unread notifications for the user.
  Stream<int> streamUnreadCount(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Client-side helper to create a notification document.
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? reportId,
    String? reportNumber,
    Map<String, dynamic> data = const {},
  }) async {
    await _notifications.add({
      'userId': userId,
      'reportId': reportId,
      'reportNumber': reportNumber,
      'title': title,
      'body': body,
      'type': type.key,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}