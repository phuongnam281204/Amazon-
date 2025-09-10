import 'package:amazon_clone/services/notification_service.dart';
import 'package:amazon_clone/models/notification.dart' as model;
import 'package:flutter/material.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  List<model.Notification> _notifications = [];
  Timer? _refreshTimer;

  int get unreadCount => _unreadCount;
  List<model.Notification> get notifications => _notifications;

  Future<void> fetchUnreadCount(BuildContext context) async {
    try {
      _unreadCount = await _notificationService.getUnreadCount(context);
      notifyListeners();
    } catch (e) {
      // Handle error silently
      _unreadCount = 0;
    }
  }

  Future<void> fetchNotifications(BuildContext context) async {
    try {
      _notifications = await _notificationService.fetchNotifications(context);
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      // Handle error silently
      _notifications = [];
      _unreadCount = 0;
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications
        .where((notification) => !notification.isRead)
        .length;
  }

  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  void incrementUnreadCount() {
    _unreadCount++;
    notifyListeners();
  }

  void markAsRead(String notificationId, BuildContext context) {
    _notificationService.markAsRead(
      context: context,
      notificationId: notificationId,
      onSuccess: () {
        // Update local state immediately
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          decrementUnreadCount();
        }
      },
    );
  }

  void markAllAsRead(BuildContext context) {
    _notificationService.markAllAsRead(
      context: context,
      onSuccess: () {
        // Update local state immediately
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
          }
        }
        resetUnreadCount();
      },
    );
  }

  // Start periodic refresh for real-time updates
  void startPeriodicRefresh(BuildContext context) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchUnreadCount(context);
    });
  }

  // Stop periodic refresh
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopPeriodicRefresh();
    super.dispose();
  }
}
