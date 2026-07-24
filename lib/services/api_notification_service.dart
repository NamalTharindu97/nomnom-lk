import '../models/notification_model.dart';
import 'api_client.dart';

class ApiNotificationService {
  ApiNotificationService(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> fetchNotifications({int page = 1}) async {
    final response = await _client.get('/notifications', queryParameters: {
      'page': page,
      'per_page': 20,
    });
    final data = response['data'] as List;
    return data
        .map((json) =>
            AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final response = await _client.get('/notifications/unread-count');
    return (response['data']?['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await _client.put('/notifications/$id/read', {});
  }

  Future<void> markAllAsRead() async {
    await _client.put('/notifications/read-all', {});
  }
}
