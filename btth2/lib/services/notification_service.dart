import 'dart:async';
import 'package:flutter/foundation.dart';

class InAppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'borrow_request', 'borrow_approved', 'borrow_rejected', 'borrow_returned', 'system'
  final String? relatedDocId;
  final DateTime timestamp;
  bool isRead;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedDocId,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService {
  static final List<InAppNotification> _notifications = [];
  static final StreamController<List<InAppNotification>> _notifStream =
      StreamController<List<InAppNotification>>.broadcast();

  static Stream<List<InAppNotification>> get notificationStream => _notifStream.stream;
  static List<InAppNotification> get allNotifications => List.unmodifiable(_notifications);
  static int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static void notify({
    required String title,
    required String message,
    required String type,
    String? relatedDocId,
  }) {
    final item = InAppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${_notifications.length}',
      title: title,
      message: message,
      type: type,
      relatedDocId: relatedDocId,
      timestamp: DateTime.now(),
      isRead: false,
    );
    _notifications.insert(0, item);
    _notifStream.add(List.unmodifiable(_notifications));
    debugPrint('[NotificationService] New notification: $title - $message');
  }

  static void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      _notifStream.add(List.unmodifiable(_notifications));
    }
  }

  static void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _notifStream.add(List.unmodifiable(_notifications));
  }

  static void clearAll() {
    _notifications.clear();
    _notifStream.add([]);
  }
}
