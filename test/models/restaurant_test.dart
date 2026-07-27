import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/restaurant.dart';
import 'package:nomnom_lk/models/social_link.dart';

void main() {
  group('Restaurant', () {
    test('fromJson parses complete restaurant', () {
      final json = {
        'id': 'r1',
        'name': 'Pizza Hut',
        'slug': 'pizza-hut',
        'phone': '+94112345678',
        'description': 'Best pizza in town',
        'cuisine_tags': ['italian', 'pizza'],
        'status': 'approved',
        'cover_image': 'https://img.com/cover.jpg',
        'social_links': [
          {'platform': 'instagram', 'url': 'https://instagram.com/ph'},
        ],
        'order_platforms': ['uber_eats', 'pickme'],
      };
      final r = Restaurant.fromJson(json);
      expect(r.id, 'r1');
      expect(r.name, 'Pizza Hut');
      expect(r.slug, 'pizza-hut');
      expect(r.phone, '+94112345678');
      expect(r.description, 'Best pizza in town');
      expect(r.cuisineTags, ['italian', 'pizza']);
      expect(r.status, 'approved');
      expect(r.coverImage, 'https://img.com/cover.jpg');
      expect(r.socialLinks, hasLength(1));
      expect(r.orderPlatforms, ['uber_eats', 'pickme']);
    });

    test('fromJson handles nullable fields', () {
      final json = {
        'id': 'r2',
        'name': 'KFC',
        'slug': 'kfc',
      };
      final r = Restaurant.fromJson(json);
      expect(r.phone, isNull);
      expect(r.description, '');
      expect(r.cuisineTags, isEmpty);
      expect(r.status, 'approved');
      expect(r.coverImage, isNull);
      expect(r.socialLinks, isEmpty);
      expect(r.orderPlatforms, isEmpty);
    });

    test('toJson roundtrip', () {
      const r = Restaurant(
        id: 'r3',
        name: 'Burger King',
        slug: 'burger-king',
        description: 'Whopper',
        cuisineTags: ['burger'],
        status: 'approved',
        socialLinks: [SocialLink(platform: 'website', url: 'https://bk.com')],
        orderPlatforms: ['uber_eats'],
      );
      final json = r.toJson();
      final restored = Restaurant.fromJson(json);
      expect(restored.id, r.id);
      expect(restored.name, r.name);
      expect(restored.cuisineTags, r.cuisineTags);
      expect(restored.orderPlatforms, r.orderPlatforms);
      expect(restored.socialLinks, hasLength(1));
    });

    test('copyWith updates name', () {
      const r = Restaurant(
        id: 'r4',
        name: 'Old',
        slug: 'old',
        description: 'd',
        cuisineTags: [],
        status: 'approved',
      );
      final updated = r.copyWith(name: 'New');
      expect(updated.name, 'New');
      expect(updated.id, 'r4');
      expect(updated.slug, 'old');
      expect(updated.description, 'd');
    });
  });
}
