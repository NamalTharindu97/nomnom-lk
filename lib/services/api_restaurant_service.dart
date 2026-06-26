import '../models/paginated_response.dart';
import '../models/restaurant.dart';
import 'api_client.dart';

class ApiRestaurantService {
  ApiRestaurantService(this._client);

  final ApiClient _client;

  Future<PaginatedResponse<Restaurant>> fetchRestaurants({int page = 1}) async {
    final response = await _client.get('/restaurants', queryParameters: {
      'page': page,
      'per_page': 20,
    });
    return PaginatedResponse.fromJson(response, Restaurant.fromJson);
  }

  Future<Restaurant> getRestaurant(String id) async {
    final response = await _client.get('/restaurants/$id');
    return Restaurant.fromJson(response['data'] as Map<String, dynamic>);
  }
}
