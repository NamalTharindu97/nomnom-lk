import '../core/api_config.dart';
import '../models/offer.dart';
import 'api_client.dart';

class ApiOfferService {
  ApiOfferService(this._client);

  final ApiClient _client;

  Future<List<Offer>> fetchOffers({String? query, int page = 1}) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': ApiConfig.perPage,
    };
    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }

    final response = await _client.get('/offers', queryParameters: params);
    final data = response['data'] as List;
    return data
        .map((json) => Offer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Offer> getOffer(String id) async {
    final response = await _client.get('/offers/$id');
    return Offer.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Offer> createOffer(Map<String, dynamic> data) async {
    final response = await _client.post('/offers', data);
    return Offer.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Offer>> search({
    required String query,
    int page = 1,
    String? sort,
    String? cuisine,
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    final params = <String, dynamic>{
      'q': query,
      'page': page,
      'per_page': ApiConfig.perPage,
    };
    if (sort != null) params['sort'] = sort;
    if (cuisine != null) params['cuisine'] = cuisine;
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    if (radiusKm != null) params['radius_km'] = radiusKm;

    final response = await _client.get('/search', queryParameters: params);
    final data = response['data'] as List;
    return data
        .map((json) => Offer.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
