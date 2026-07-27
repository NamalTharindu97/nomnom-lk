import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/banner.dart';

void main() {
  group('FeaturedBanner', () {
    test('fromJson parses complete banner', () {
      final json = {
        'id': 'b1',
        'image': 'https://img.com/banner.jpg',
        'link_type': 'offer',
        'link_value': 'o1',
        'title': 'Summer Sale',
        'sponsor_name': 'Pizza Hut',
      };
      final banner = FeaturedBanner.fromJson(json);
      expect(banner.id, 'b1');
      expect(banner.image, 'https://img.com/banner.jpg');
      expect(banner.linkType, 'offer');
      expect(banner.linkValue, 'o1');
      expect(banner.title, 'Summer Sale');
      expect(banner.sponsorName, 'Pizza Hut');
    });

    test('fromJson handles nullable fields', () {
      final json = {
        'id': 'b2',
        'image': 'https://img.com/b.jpg',
        'link_type': 'url',
        'link_value': 'https://example.com',
      };
      final banner = FeaturedBanner.fromJson(json);
      expect(banner.title, isNull);
      expect(banner.sponsorName, isNull);
    });
  });
}
