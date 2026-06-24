import '../models/offer.dart';
import 'api_client.dart';

class ApiFavoritesService {
  ApiFavoritesService(this._client);

  final ApiClient _client;

  Future<List<Offer>> fetchFavorites() async {
    final response = await _client.get('/favorites');
    final data = response['data'] as List;
    return data
        .map((json) => Offer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(String offerId) async {
    await _client.post('/favorites', {'offer_id': offerId});
  }

  Future<void> removeFavorite(String offerId) async {
    await _client.delete('/favorites/$offerId');
  }
}
