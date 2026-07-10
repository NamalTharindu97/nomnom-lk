import '../models/banner.dart';
import 'api_client.dart';

class ApiBannerService {
  ApiBannerService(this._client);

  final ApiClient _client;

  Future<List<FeaturedBanner>> fetchActiveBanners() async {
    final response = await _client.get('/banners/active');
    final data = response['data'] as List<dynamic>;
    return data
        .map((j) => FeaturedBanner.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> trackClick(String bannerId) async {
    await _client.post('/banners/$bannerId/click', null);
  }
}
