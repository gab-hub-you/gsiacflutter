import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => [..._notifications];
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);
      
      _notifications = (response as List).map((n) => AppNotification.fromJson(n)).toList();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
      
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index >= 0) {
        _notifications[index].isRead = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId);
      
      for (var n in _notifications) {
        n.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
    }
  }

  Future<void> removeNotification(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error removing notification: $e");
    }
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      };

      await _supabase.from('notifications').insert(notificationData);
      await fetchNotifications(userId);
    } catch (e) {
      debugPrint("Error adding notification: $e");
    }
  }
}
