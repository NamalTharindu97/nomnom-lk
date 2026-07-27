import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/offer.dart';
import 'package:nomnom_lk/models/social_link.dart';

Map<String, dynamic> makeOfferJson({
  double originalPrice = 1000,
  double offerPrice = 600,
  String title = 'Test Offer',
  String? titleSi,
  String? titleTa,
  String? descriptionSi,
  String? descriptionTa,
  List<String> imageUrls = const ['https://img.com/1.jpg'],
  List<String> cuisineTags = const ['spicy'],
  List<String> categoryIds = const ['c1'],
  List<SocialLink> socialLinks = const [],
  List<String> orderPlatforms = const [],
  bool isFavorited = false,
}) {
  return {
    'id': 'o1',
    'restaurant': {
      'id': 'r1',
      'name': 'Test Restaurant',
      'slug': 'test-restaurant',
      'cuisine_tags': cuisineTags,
      'social_links': SocialLink.listToJson(socialLinks),
      'order_platforms': orderPlatforms,
    },
    'title': title,
    'title_si': titleSi,
    'title_ta': titleTa,
    'description': 'A test offer description',
    'description_si': descriptionSi,
    'description_ta': descriptionTa,
    'original_price': originalPrice,
    'offer_price': offerPrice,
    'image_urls': imageUrls,
    'category_ids': categoryIds,
    'end_date': '2026-08-01T00:00:00.000',
    'is_favorited': isFavorited,
  };
}

void main() {
  group('Offer', () {
    group('fromJson', () {
      test('parses complete offer', () {
        final offer = Offer.fromJson(makeOfferJson());
        expect(offer.id, 'o1');
        expect(offer.restaurantId, 'r1');
        expect(offer.restaurantName, 'Test Restaurant');
        expect(offer.restaurantSlug, 'test-restaurant');
        expect(offer.title, 'Test Offer');
        expect(offer.description, 'A test offer description');
        expect(offer.originalPrice, 1000);
        expect(offer.offerPrice, 600);
        expect(offer.imageUrls, ['https://img.com/1.jpg']);
        expect(offer.cuisineTags, ['spicy']);
        expect(offer.categoryIds, ['c1']);
        expect(offer.endDate.year, 2026);
        expect(offer.isFavorite, isFalse);
        expect(offer.socialLinks, isEmpty);
        expect(offer.orderPlatforms, isEmpty);
      });

      test('handles nullable fields', () {
        final json = makeOfferJson(
          cuisineTags: [],
          categoryIds: [],
          imageUrls: [],
          isFavorited: false,
        );
        // Remove optional nested fields
        json['restaurant'].remove('social_links');
        json['restaurant'].remove('order_platforms');
        json.remove('title_si');
        json.remove('title_ta');
        json.remove('description_si');
        json.remove('description_ta');
        final offer = Offer.fromJson(json);
        expect(offer.titleSi, isNull);
        expect(offer.titleTa, isNull);
        expect(offer.cuisineTags, isEmpty);
        expect(offer.categoryIds, isEmpty);
        expect(offer.imageUrls, isEmpty);
        expect(offer.socialLinks, isEmpty);
        expect(offer.orderPlatforms, isEmpty);
      });

      test('parses social_links', () {
        final socialLinks = [
          SocialLink(platform: 'instagram', url: 'https://ig.com/ph'),
          SocialLink(platform: 'facebook', url: 'https://fb.com/ph'),
        ];
        final offer = Offer.fromJson(makeOfferJson(socialLinks: socialLinks));
        expect(offer.socialLinks, hasLength(2));
        expect(offer.instagramUrl, 'https://ig.com/ph');
        expect(offer.facebookUrl, 'https://fb.com/ph');
      });

      test('parses order_platforms', () {
        final offer = Offer.fromJson(makeOfferJson(orderPlatforms: ['uber_eats', 'pickme']));
        expect(offer.orderPlatforms, ['uber_eats', 'pickme']);
      });
    });

    group('toJson', () {
      test('roundtrip preserves data', () {
        final original = Offer.fromJson(makeOfferJson(
          titleSi: 'සිංහල',
          titleTa: 'தமிழ்',
          orderPlatforms: ['uber_eats'],
        ));
        final json = original.toJson();
        final restored = Offer.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.titleSi, original.titleSi);
        expect(restored.titleTa, original.titleTa);
        expect(restored.originalPrice, original.originalPrice);
        expect(restored.offerPrice, original.offerPrice);
        expect(restored.restaurantId, original.restaurantId);
        expect(restored.orderPlatforms, original.orderPlatforms);
      });
    });

    group('computed properties', () {
      test('discountPercent calculates correctly', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 1000, offerPrice: 600));
        expect(offer.discountPercent, 40);
      });

      test('discountPercent handles zero original', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 0, offerPrice: 0));
        expect(offer.discountPercent, 0);
      });

      test('discountPercent handles equal prices', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 500, offerPrice: 500));
        expect(offer.discountPercent, 0);
      });

      test('discountPercent clamps to 100', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 100, offerPrice: 0));
        expect(offer.discountPercent, 100);
      });

      test('saving calculates correctly', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 1000, offerPrice: 600));
        expect(offer.saving, 400);
      });
    });

    group('discountLabel', () {
      test('percentage label when discount > 0', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 1000, offerPrice: 600));
        expect(offer.discountLabel, '40%');
      });

      test('saving label when discount = 0', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 500, offerPrice: 500));
        expect(offer.discountLabel, '0');
      });
    });

    group('discountLabelLocalized', () {
      test('percentage label for any locale when discount > 0', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 1000, offerPrice: 600));
        expect(offer.discountLabelLocalized('en'), '40%');
        expect(offer.discountLabelLocalized('si'), '40%');
        expect(offer.discountLabelLocalized('ta'), '40%');
      });

      test('sinhala prefix when no discount', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 500, offerPrice: 500));
        expect(offer.discountLabelLocalized('si'), 'රු. 0');
      });

      test('tamil prefix when no discount', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 500, offerPrice: 500));
        expect(offer.discountLabelLocalized('ta'), 'ரூ. 0');
      });

      test('english prefix when no discount', () {
        final offer = Offer.fromJson(makeOfferJson(originalPrice: 500, offerPrice: 500));
        expect(offer.discountLabelLocalized('en'), 'Rs. 0');
      });
    });

    group('localizedTitle', () {
      test('returns en title', () {
        final offer = Offer.fromJson(makeOfferJson(title: 'English'));
        expect(offer.localizedTitle('en'), 'English');
      });

      test('falls back to en for unknown locale', () {
        final offer = Offer.fromJson(makeOfferJson(title: 'English'));
        expect(offer.localizedTitle('fr'), 'English');
      });

      test('returns si title when available', () {
        final offer = Offer.fromJson(makeOfferJson(title: 'English', titleSi: 'සිංහල'));
        expect(offer.localizedTitle('si'), 'සිංහල');
      });

      test('returns ta title when available', () {
        final offer = Offer.fromJson(makeOfferJson(title: 'English', titleTa: 'தமிழ்'));
        expect(offer.localizedTitle('ta'), 'தமிழ்');
      });
    });

    group('primaryImage', () {
      test('returns first image', () {
        final offer = Offer.fromJson(makeOfferJson(imageUrls: ['a.jpg', 'b.jpg']));
        expect(offer.primaryImage, 'a.jpg');
      });

      test('returns empty string for empty list', () {
        final offer = Offer.fromJson(makeOfferJson(imageUrls: []));
        expect(offer.primaryImage, '');
      });
    });

    group('social link getters', () {
      test('instagramUrl finds instagram link', () {
        final links = [SocialLink(platform: 'instagram', url: 'https://ig.com')];
        final offer = Offer.fromJson(makeOfferJson(socialLinks: links));
        expect(offer.instagramUrl, 'https://ig.com');
      });

      test('instagramUrl returns null when absent', () {
        final offer = Offer.fromJson(makeOfferJson());
        expect(offer.instagramUrl, isNull);
      });

      test('facebookUrl finds facebook link', () {
        final links = [SocialLink(platform: 'facebook', url: 'https://fb.com')];
        final offer = Offer.fromJson(makeOfferJson(socialLinks: links));
        expect(offer.facebookUrl, 'https://fb.com');
      });

      test('websiteUrl finds website link', () {
        final links = [SocialLink(platform: 'website', url: 'https://web.com')];
        final offer = Offer.fromJson(makeOfferJson(socialLinks: links));
        expect(offer.websiteUrl, 'https://web.com');
      });
    });

    group('copyWith', () {
      test('updates title', () {
        final offer = Offer.fromJson(makeOfferJson());
        final updated = offer.copyWith(title: 'New Title');
        expect(updated.title, 'New Title');
        expect(updated.id, offer.id);
        expect(updated.originalPrice, offer.originalPrice);
      });

      test('toggles isFavorite', () {
        final offer = Offer.fromJson(makeOfferJson(isFavorited: false));
        final favorited = offer.copyWith(isFavorite: true);
        expect(favorited.isFavorite, isTrue);
      });
    });
  });
}
