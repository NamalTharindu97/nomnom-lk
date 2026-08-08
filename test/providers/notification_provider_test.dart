import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/notification_model.dart';
import 'package:nomnom_lk/providers/notification_provider.dart';

import '../helpers/mocks.dart';

AppNotification _makeNotification({
  String id = 'n1',
  String title = 'Test',
  String body = 'Body',
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    type: 'offer',
    title: title,
    body: body,
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  late MockApiNotificationService service;
  late MockNotificationStore store;
  late NotificationProvider provider;

  setUp(() {
    service = MockApiNotificationService();
    store = MockNotificationStore();
    provider = NotificationProvider(service, notificationStore: store);
  });

  group('loadNotifications', () {
    test('populates list from service', () async {
      service.notifications = [
        _makeNotification(id: 'n1', title: 'First'),
        _makeNotification(id: 'n2', title: 'Second'),
      ];

      await provider.loadNotifications();

      expect(provider.notifications, hasLength(2));
      expect(provider.notifications[0].id, 'n1');
      expect(provider.notifications[1].id, 'n2');
      expect(provider.isLoading, isFalse);
    });

    test('saves fetched notifications to store', () async {
      service.notifications = [_makeNotification(id: 'n1')];

      await provider.loadNotifications();

      expect(store.cachedNotifications, isNotNull);
      expect(store.cachedNotifications, hasLength(1));
      expect(store.cachedNotifications![0]['id'], 'n1');
    });

    test('sets error message on failure', () async {
      service.fetchNotificationsThrows = true;

      await provider.loadNotifications();

      expect(provider.error, 'failedLoadPullRetry');
      expect(provider.isLoading, isFalse);
    });

    test('loads from cache on failure', () async {
      final cached = [_makeNotification(id: 'cached-1', title: 'Cached')];
      store.cachedNotifications = cached.map((n) => n.toJson()).toList();
      service.fetchNotificationsThrows = true;

      await provider.loadNotifications();

      expect(provider.notifications, hasLength(1));
      expect(provider.notifications[0].id, 'cached-1');
    });
  });

  group('loadUnreadCount', () {
    test('updates unread count from service', () async {
      service.unreadCount = 5;

      await provider.loadUnreadCount();

      expect(provider.unreadCount, 5);
    });

    test('silently ignores errors', () async {
      service.fetchUnreadCountThrows = true;

      await provider.loadUnreadCount();

      expect(provider.unreadCount, 0);
    });
  });

  group('markAsRead', () {
    test('marks notification as read and decrements count', () async {
      service.notifications = [
        _makeNotification(id: 'n1', isRead: false),
        _makeNotification(id: 'n2', isRead: false),
      ];
      await provider.loadNotifications();
      provider.unreadCount; // read initial
      // Simulate unread count of 2
      service.unreadCount = 2;
      await provider.loadUnreadCount();
      expect(provider.unreadCount, 2);

      await provider.markAsRead('n1');

      expect(provider.notifications[0].isRead, isTrue);
      expect(provider.notifications[1].isRead, isFalse);
      expect(provider.unreadCount, 1);
      expect(store.cachedNotifications![0]['is_read'], isTrue);
    });

    test('does nothing for already-read notification', () async {
      service.notifications = [
        _makeNotification(id: 'n1', isRead: true),
      ];
      await provider.loadNotifications();
      service.unreadCount = 0;
      await provider.loadUnreadCount();

      await provider.markAsRead('n1');

      expect(provider.notifications[0].isRead, isTrue);
      expect(provider.unreadCount, 0);
    });
  });

  group('markAllAsRead', () {
    test('marks all as read and resets count', () async {
      service.notifications = [
        _makeNotification(id: 'n1', isRead: false),
        _makeNotification(id: 'n2', isRead: false),
      ];
      await provider.loadNotifications();
      service.unreadCount = 2;
      await provider.loadUnreadCount();

      await provider.markAllAsRead();

      expect(provider.notifications.every((n) => n.isRead), isTrue);
      expect(provider.unreadCount, 0);
      expect(
        store.cachedNotifications!
            .every((notification) => notification['is_read'] == true),
        isTrue,
      );
    });
  });

  test('resetForAccountChange clears private notification state', () async {
    service.notifications = [_makeNotification()];
    service.unreadCount = 1;
    await provider.loadNotifications();
    await provider.loadUnreadCount();

    provider.resetForAccountChange();

    expect(provider.notifications, isEmpty);
    expect(provider.unreadCount, 0);
    expect(provider.error, isNull);
  });
}
