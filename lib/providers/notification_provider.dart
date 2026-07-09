import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/api_notification_service.dart';
import '../services/local/notification_store.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._service, {required NotificationStore notificationStore})
      : _notificationStore = notificationStore;

  final ApiNotificationService _service;
  final NotificationStore _notificationStore;

  List<AppNotification> _notifications = const [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications() async {
    _setLoading(true);
    _error = null;
    try {
      _notifications = await _service.fetchNotifications();
      await _notificationStore.saveNotifications(
        _notifications.map((n) => n.toJson()).toList(),
      );
    } catch (e) {
      _error = 'Failed to load notifications.';
      debugPrint('Failed to load notifications: $e');
      final cached = _notificationStore.getNotifications();
      if (cached != null) {
        _notifications = cached
            .map((n) => AppNotification.fromJson(n))
            .toList();
      }
    }
    _setLoading(false);
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _service.fetchUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] =
            _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(growable: false);
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
