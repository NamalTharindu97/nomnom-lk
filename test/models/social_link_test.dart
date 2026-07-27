import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/social_link.dart';

void main() {
  group('SocialLink', () {
    test('fromJson parses link', () {
      final json = {'platform': 'instagram', 'url': 'https://instagram.com/test'};
      final link = SocialLink.fromJson(json);
      expect(link.platform, 'instagram');
      expect(link.url, 'https://instagram.com/test');
    });

    test('toJson roundtrip', () {
      const link = SocialLink(platform: 'facebook', url: 'https://facebook.com/test');
      final json = link.toJson();
      final restored = SocialLink.fromJson(json);
      expect(restored.platform, link.platform);
      expect(restored.url, link.url);
    });

    test('listFromJson with null returns empty list', () {
      final result = SocialLink.listFromJson(null);
      expect(result, isEmpty);
    });

    test('listFromJson with list parses each element', () {
      final json = [
        {'platform': 'instagram', 'url': 'https://ig.com/a'},
        {'platform': 'facebook', 'url': 'https://fb.com/b'},
      ];
      final result = SocialLink.listFromJson(json);
      expect(result, hasLength(2));
      expect(result[0].platform, 'instagram');
      expect(result[1].platform, 'facebook');
    });
  });
}
