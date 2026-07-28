import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/api_notification_service.dart';
import '../services/local/notification_store.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._service,
      {required NotificationStore notificationStore})
      : _notificationStore = notificationStore;

  final ApiNotificationService _service;
  final NotificationStore _notificationStore;

  List<AppNotification> _notifications = const [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  int _notificationsRequest = 0;
  int _unreadRequest = 0;
  int _accountGeneration = 0;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications() async {
    final accountGeneration = _accountGeneration;
    final request = ++_notificationsRequest;
    _setLoading(true);
    _error = null;
    try {
      final notifications = await _service.fetchNotifications();
      if (request != _notificationsRequest ||
          accountGeneration != _accountGeneration) {
        return;
      }
      _notifications = notifications;
      await _notificationStore.saveNotifications(
        _notifications.map((n) => n.toJson()).toList(),
      );
    } catch (e) {
      if (request != _notificationsRequest ||
          accountGeneration != _accountGeneration) {
        return;
      }
      _error = 'failedLoadPullRetry';
      debugPrint('Failed to load notifications: $e');
      final cached = _notificationStore.getNotifications();
      if (cached != null) {
        _notifications =
            cached.map((n) => AppNotification.fromJson(n)).toList();
      }
    }
    _setLoading(false);
  }

  Future<void> loadUnreadCount() async {
    final accountGeneration = _accountGeneration;
    final request = ++_unreadRequest;
    try {
      final unreadCount = await _service.fetchUnreadCount();
      if (request != _unreadRequest ||
          accountGeneration != _accountGeneration) {
        return;
      }
      _unreadCount = unreadCount;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final accountGeneration = _accountGeneration;
    _notificationsRequest++;
    _unreadRequest++;
    try {
      await _service.markAsRead(id);
      if (accountGeneration != _accountGeneration) return;
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        await _saveNotifications();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final accountGeneration = _accountGeneration;
    _notificationsRequest++;
    _unreadRequest++;
    try {
      await _service.markAllAsRead();
      if (accountGeneration != _accountGeneration) return;
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(growable: false);
      _unreadCount = 0;
      await _saveNotifications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveNotifications() {
    return _notificationStore.saveNotifications(
      _notifications.map((notification) => notification.toJson()).toList(),
    );
  }

  void resetForAccountChange() {
    _accountGeneration++;
    _notificationsRequest++;
    _unreadRequest++;
    _notifications = const [];
    _isLoading = false;
    _error = null;
    _unreadCount = 0;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
