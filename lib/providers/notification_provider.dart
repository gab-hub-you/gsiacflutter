import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;

  // Pagination
  static const int _pageSize = 20;
  bool _hasMore = true;

  List<AppNotification> get notifications => [..._notifications];
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Subscribes to Supabase Realtime for live notification updates.
  void subscribeToRealtime(String userId) {
    // Unsubscribe from any existing channel first
    unsubscribeFromRealtime();

    _realtimeChannel = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newNotification = AppNotification.fromJson(payload.newRecord);
            _notifications.insert(0, newNotification);
            notifyListeners();
          },
        )
        .subscribe();
  }

  /// Unsubscribes from the Realtime channel.
  void unsubscribeFromRealtime() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  /// Fetches paginated notifications for a user.
  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final from = _notifications.length;
      final to = from + _pageSize - 1;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .range(from, to);
      
      final newItems = (response as List).map((n) => AppNotification.fromJson(n)).toList();
      
      if (from == 0) {
        _notifications.clear();
      }
      _notifications.addAll(newItems);
      _hasMore = newItems.length >= _pageSize;
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the next page of notifications.
  Future<void> fetchMoreNotifications(String userId) async {
    if (!_hasMore || _isLoading) return;
    await fetchNotifications(userId);
  }

  void _resetPagination() {
    _notifications.clear();
    _hasMore = true;
  }

  /// Refreshes from the beginning (pull-to-refresh).
  Future<void> refreshNotifications(String userId) async {
    _resetPagination();
    await fetchNotifications(userId);
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
      // No need to manually fetch — Realtime will push the new notification
    } catch (e) {
      debugPrint("Error adding notification: $e");
    }
  }
}
