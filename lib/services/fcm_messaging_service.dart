import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/notification_provider.dart';
import 'api_client.dart';

FcmMessagingService? fcmService;

@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {}

class FcmMessagingService {
  FcmMessagingService({
    required ApiClient apiClient,
    required NotificationProvider notificationProvider,
  })  : _apiClient = apiClient,
        _notificationProvider = notificationProvider {
    fcmService = this;
  }

  final ApiClient _apiClient;
  final NotificationProvider _notificationProvider;
  final _messaging = FirebaseMessaging.instance;
  final _notifsPlugin = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();

  String? _currentToken;
  void Function(String?)? _onNavigate;

  Future<void> initialize({void Function(String?)? onNavigate}) async {
    _onNavigate = onNavigate;
    await _initLocalNotifications();
    await _getToken();
    _setupTokenRefresh();
    _setupForegroundHandler();
    _setupBackgroundHandler();
    _setupTapHandler();
    _handleInitialMessage();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }

  Future<void> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('fcm_token_migrated') != true) {
        try {
          debugPrint('FCM one-time token migration: deleting old token...');
          await _messaging.deleteToken();
          await prefs.setBool('fcm_token_migrated', true);
          debugPrint('FCM migration done');
        } catch (e) {
          debugPrint(
            'FCM migration deleteToken error: ${e.runtimeType}',
          );
        }
      }
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        await _registerToken(_currentToken!);
      }
    } catch (e) {
      debugPrint('FCM getToken error: ${e.runtimeType}');
    }
  }

  void _setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _registerToken(newToken);
    });
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  void _setupTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _handleMessageTap(message);
    }
  }

  void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    _notificationProvider.loadUnreadCount();
    _apiClient.invalidateCache('/notifications');
    _notificationProvider.loadNotifications();

    final title = message.notification?.title ?? 'NomNom LK';
    final body = message.notification?.body ?? '';
    final data = message.data;

    const androidDetails = AndroidNotificationDetails(
      'nomnom_notifications',
      'NomNom Notifications',
      channelDescription: 'Daily deals and updates from NomNom LK',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Store payload data for tap handling
    final payload = data['type'] ?? data['offer_id'] ?? 'notification';

    await _notifsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload.toString(),
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    _navigateFromPayload(response.payload);
  }

  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final offerId = data['offer_id'];
    _navigateFromPayload(type ?? offerId ?? 'notification');
  }

  void _navigateFromPayload(String? payload) {
    _onNavigate?.call(payload);
  }

  Future<void> registerCurrentToken() async {
    if (_currentToken == null) return;
    await _registerToken(_currentToken!);
  }

  Future<void> _registerToken(String token) async {
    if (await _storage.read(key: 'access_token') == null) return;
    try {
      await _apiClient.post('/devices', {
        'token': token,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('FCM register error: ${e.runtimeType}');
    }
  }

  Future<void> unregisterToken() async {
    if (_currentToken == null) return;
    try {
      await _apiClient.delete('/devices', data: {'token': _currentToken});
      _currentToken = null;
    } catch (e) {
      debugPrint('FCM unregister error: ${e.runtimeType}');
    }
  }
}
