import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      title: 'Request Approved',
      message: 'Your request for Barangay Clearance (TRK-100201) has been approved.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.success,
    ),
    AppNotification(
      id: '2',
      title: 'Request Pending',
      message: 'Your request for Business Permit (TRK-100205) is now pending review.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.warning,
    ),
    AppNotification(
      id: '3',
      title: 'Request Denied',
      message: 'Your request for Senior Citizen ID (TRK-100199) was denied due to incomplete documents.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.error,
    ),
  ];

  List<AppNotification> get notifications => [..._notifications];

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
    notifyListeners();
  }
}
