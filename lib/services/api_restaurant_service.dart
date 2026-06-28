import '../models/paginated_response.dart';
import '../models/restaurant.dart';
import 'api_client.dart';

class ApiRestaurantService {
  ApiRestaurantService(this._client);

  final ApiClient _client;

  Future<PaginatedResponse<Restaurant>> fetchRestaurants({String? query, int page = 1}) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': 20,
    };
    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }
    final response = await _client.get('/restaurants', queryParameters: params);
    return PaginatedResponse.fromJson(response, Restaurant.fromJson);
  }

  Future<Restaurant> getRestaurant(String id) async {
    final response = await _client.get('/restaurants/$id');
    return Restaurant.fromJson(response['data'] as Map<String, dynamic>);
  }
}
