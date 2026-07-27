import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/services/api_platform_service.dart';

void main() {
  group('PlatformData', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'id': '1',
        'slug': 'uber-eats',
        'display_name': 'Uber Eats',
        'primary_color': '#06C167',
        'deep_link_scheme': 'ubereats',
        'logo_url': 'https://cdn.example.com/uber-eats.png',
      };

      final data = PlatformData.fromJson(json);

      expect(data.id, '1');
      expect(data.slug, 'uber-eats');
      expect(data.displayName, 'Uber Eats');
      expect(data.primaryColor, '#06C167');
      expect(data.deepLinkScheme, 'ubereats');
      expect(data.logoUrl, 'https://cdn.example.com/uber-eats.png');
    });

    test('fromJson with logoUrl', () {
      final json = <String, dynamic>{
        'id': '2',
        'slug': 'pickme',
        'display_name': 'PickMe',
        'primary_color': '#00B14F',
        'deep_link_scheme': 'pickme',
        'logo_url': 'https://cdn.example.com/pickme.svg',
      };

      final data = PlatformData.fromJson(json);

      expect(data.logoUrl, isNotNull);
      expect(data.logoUrl, 'https://cdn.example.com/pickme.svg');
    });

    test('fromJson null logoUrl', () {
      final json = <String, dynamic>{
        'id': '3',
        'slug': 'foodpanda',
        'display_name': 'Foodpanda',
        'primary_color': '#D70F64',
        'deep_link_scheme': 'foodpanda',
        'logo_url': null,
      };

      final data = PlatformData.fromJson(json);

      expect(data.logoUrl, isNull);
    });
  });

  group('SocialPlatformData', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'id': '10',
        'slug': 'instagram',
        'display_name': 'Instagram',
        'primary_color': '#E4405F',
        'logo_url': 'https://cdn.example.com/instagram.png',
      };

      final data = SocialPlatformData.fromJson(json);

      expect(data.id, '10');
      expect(data.slug, 'instagram');
      expect(data.displayName, 'Instagram');
      expect(data.primaryColor, '#E4405F');
      expect(data.logoUrl, 'https://cdn.example.com/instagram.png');
    });

    test('fromJson null logoUrl', () {
      final json = <String, dynamic>{
        'id': '11',
        'slug': 'facebook',
        'display_name': 'Facebook',
        'primary_color': '#1877F2',
        'logo_url': null,
      };

      final data = SocialPlatformData.fromJson(json);

      expect(data.logoUrl, isNull);
      expect(data.id, '11');
      expect(data.slug, 'facebook');
      expect(data.displayName, 'Facebook');
      expect(data.primaryColor, '#1877F2');
    });
  });
}
