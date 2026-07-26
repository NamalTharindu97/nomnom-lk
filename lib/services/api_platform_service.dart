import '../core/api_config.dart';
import 'api_client.dart';

class ApiPlatformService {
  final ApiClient _client;

  ApiPlatformService(this._client);

  Future<List<PlatformData>> fetchPlatforms() async {
    final response = await _client.get('/order-platforms');
    final list = response['data'] as List? ?? [];
    return list.map((json) => PlatformData.fromJson(json as Map<String, dynamic>)).toList();
  }
}

class ApiSocialPlatformService {
  final ApiClient _client;

  ApiSocialPlatformService(this._client);

  Future<List<SocialPlatformData>> fetchPlatforms() async {
    final response = await _client.get('/social-platforms');
    final list = response['data'] as List? ?? [];
    return list.map((json) => SocialPlatformData.fromJson(json as Map<String, dynamic>)).toList();
  }
}

class SocialPlatformData {
  final String id;
  final String slug;
  final String displayName;
  final String primaryColor;
  final String? logoUrl;

  SocialPlatformData({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.primaryColor,
    this.logoUrl,
  });

  factory SocialPlatformData.fromJson(Map<String, dynamic> json) {
    return SocialPlatformData(
      id: json['id'] as String,
      slug: json['slug'] as String,
      displayName: json['display_name'] as String,
      primaryColor: json['primary_color'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}

class PlatformData {
  final String id;
  final String slug;
  final String displayName;
  final String primaryColor;
  final String deepLinkScheme;
  final String? logoUrl;

  PlatformData({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.primaryColor,
    required this.deepLinkScheme,
    this.logoUrl,
  });

  factory PlatformData.fromJson(Map<String, dynamic> json) {
    return PlatformData(
      id: json['id'] as String,
      slug: json['slug'] as String,
      displayName: json['display_name'] as String,
      primaryColor: json['primary_color'] as String,
      deepLinkScheme: json['deep_link_scheme'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}
