import '../models/restaurant.dart';
import 'api_client.dart';

class ApiRestaurantService {
  ApiRestaurantService(this._client);

  final ApiClient _client;

  Future<List<Restaurant>> fetchRestaurants({int page = 1}) async {
    final response = await _client.get('/restaurants', queryParameters: {
      'page': page,
      'per_page': 20,
    });
    final data = response['data'] as List;
    return data
        .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Restaurant> getRestaurant(String id) async {
    final response = await _client.get('/restaurants/$id');
    return Restaurant.fromJson(response['data'] as Map<String, dynamic>);
  }
}
