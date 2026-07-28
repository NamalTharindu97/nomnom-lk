import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/core/api_config.dart';
import 'package:nomnom_lk/services/api_banner_service.dart';
import 'package:nomnom_lk/services/api_favorites_service.dart';
import 'package:nomnom_lk/services/api_notification_service.dart';
import 'package:nomnom_lk/services/api_offer_service.dart';
import 'package:nomnom_lk/services/api_restaurant_service.dart';

import '../helpers/mocks.dart';

final _offerJson = {
  'id': 'o1',
  'restaurant': {
    'id': 'r1',
    'name': 'Test',
    'slug': 'test',
    'cuisine_tags': ['spicy'],
    'social_links': null,
    'order_platforms': null,
  },
  'title': 'Offer',
  'description': 'Desc',
  'original_price': 1000,
  'offer_price': 600,
  'image_urls': [],
  'category_ids': [],
  'end_date': '2026-08-01T00:00:00.000',
  'is_favorited': false,
};

final _restaurantJson = {
  'id': 'r1',
  'name': 'Test Restaurant',
  'slug': 'test-restaurant',
  'description': 'A description',
  'cuisine_tags': ['spicy'],
  'social_links': null,
  'order_platforms': null,
};

final _notificationJson = {
  'id': 'n1',
  'type': 'offer',
  'title': 'Test',
  'body': 'Body text',
  'image_url': null,
  'is_read': false,
  'created_at': '2026-07-25T10:00:00Z',
};

final _bannerJson = {
  'id': 'b1',
  'image': '/api/v1/uploads/banner.jpg',
  'link_type': 'offer',
  'link_value': 'offer-1',
  'title': 'Banner',
};

Map<String, dynamic> _paginated(List<Map<String, dynamic>> items) => {
      'data': items,
      'pagination': {
        'page': 1,
        'per_page': ApiConfig.perPage,
        'total': items.length,
        'total_pages': 1,
      },
    };

void main() {
  group('ApiOfferService', () {
    late MockApiClient mock;
    late ApiOfferService service;

    setUp(() {
      mock = MockApiClient();
      service = ApiOfferService(mock);
    });

    test('fetchOffers calls correct path and params', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/offers');
        expect(queryParameters, {
          'page': 1,
          'per_page': ApiConfig.perPage,
        });
        return _paginated([_offerJson]);
      };

      final result = await service.fetchOffers();
      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'o1');
    });

    test('fetchOffers with query adds q param', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters!['q'], 'burger');
        return _paginated([_offerJson]);
      };

      final result = await service.fetchOffers(query: 'burger');
      expect(result.data, hasLength(1));
    });

    test('fetchOffers skips empty query param', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters!.containsKey('q'), isFalse);
        return _paginated([]);
      };

      await service.fetchOffers(query: '');
      await service.fetchOffers(query: null);
    });

    test('fetchOffers forwards page number', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters!['page'], 3);
        return _paginated([]);
      };

      await service.fetchOffers(page: 3);
    });

    test('force refresh invalidates the offers cache', () async {
      mock.onGet = (path, {queryParameters}) async => {
            'data': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 1,
            },
          };

      await service.fetchOffers(forceRefresh: true);

      expect(mock.lastInvalidatedPath, '/offers');
    });

    test('getOffer returns parsed offer', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/offers/o1');
        return {'data': _offerJson};
      };

      final offer = await service.getOffer('o1');
      expect(offer.id, 'o1');
      expect(offer.title, 'Offer');
      expect(offer.originalPrice, 1000);
      expect(offer.offerPrice, 600);
      expect(offer.cuisineTags, ['spicy']);
    });

    test('createOffer posts data and returns offer', () async {
      final postData = {'title': 'New Offer', 'offer_price': 500};

      mock.onPost = (path, data) async {
        expect(path, '/offers');
        expect(data, postData);
        return {'data': _offerJson};
      };

      final offer = await service.createOffer(postData);
      expect(offer.id, 'o1');
    });

    test('search passes all optional params', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/search');
        expect(queryParameters, {
          'q': 'pizza',
          'page': 2,
          'per_page': ApiConfig.perPage,
          'sort': 'price',
          'cuisine': 'italian',
          'lat': 6.9271,
          'lng': 79.8612,
          'radius_km': 5.0,
        });
        return _paginated([_offerJson]);
      };

      final result = await service.search(
        query: 'pizza',
        page: 2,
        sort: 'price',
        cuisine: 'italian',
        lat: 6.9271,
        lng: 79.8612,
        radiusKm: 5.0,
      );
      expect(result.data, hasLength(1));
    });

    test('search with only required params omits nulls', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters, {
          'q': 'sushi',
          'page': 1,
          'per_page': ApiConfig.perPage,
        });
        return _paginated([]);
      };

      await service.search(query: 'sushi');
    });
  });

  group('ApiRestaurantService', () {
    late MockApiClient mock;
    late ApiRestaurantService service;

    setUp(() {
      mock = MockApiClient();
      service = ApiRestaurantService(mock);
    });

    test('fetchRestaurants calls correct path and default params', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/restaurants');
        expect(queryParameters, {'page': 1, 'per_page': 20});
        return {
          'data': [_restaurantJson],
          'pagination': {
            'page': 1,
            'per_page': 20,
            'total': 1,
            'total_pages': 1,
          },
        };
      };

      final result = await service.fetchRestaurants();
      expect(result.data, hasLength(1));
      expect(result.data.first.name, 'Test Restaurant');
    });

    test('fetchRestaurants with query adds q param', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters!['q'], 'kfc');
        return {
          'data': [_restaurantJson],
          'pagination': {
            'page': 1,
            'per_page': 20,
            'total': 1,
            'total_pages': 1,
          },
        };
      };

      final result = await service.fetchRestaurants(query: 'kfc');
      expect(result.data, hasLength(1));
    });

    test('fetchRestaurants skips empty query', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters!.containsKey('q'), isFalse);
        return {
          'data': [],
          'pagination': {
            'page': 1,
            'per_page': 20,
            'total': 0,
            'total_pages': 1,
          },
        };
      };

      await service.fetchRestaurants(query: '');
    });

    test('getRestaurant returns parsed restaurant', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/restaurants/r1');
        return {'data': _restaurantJson};
      };

      final restaurant = await service.getRestaurant('r1');
      expect(restaurant.id, 'r1');
      expect(restaurant.name, 'Test Restaurant');
      expect(restaurant.slug, 'test-restaurant');
      expect(restaurant.cuisineTags, ['spicy']);
    });

    test('fetchRestaurants forwards page number', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters!['page'], 5);
        return {
          'data': [],
          'pagination': {
            'page': 5,
            'per_page': 20,
            'total': 0,
            'total_pages': 5,
          },
        };
      };

      final result = await service.fetchRestaurants(page: 5);
      expect(result.page, 5);
    });

    test('force refresh invalidates the restaurants cache', () async {
      mock.onGet = (path, {queryParameters}) async => {
            'data': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 1,
            },
          };

      await service.fetchRestaurants(forceRefresh: true);

      expect(mock.lastInvalidatedPath, '/restaurants');
    });
  });

  group('ApiNotificationService', () {
    late MockApiClient mock;
    late ApiNotificationService service;

    setUp(() {
      mock = MockApiClient();
      service = ApiNotificationService(mock);
    });

    test('fetchNotifications parses list', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/notifications');
        expect(queryParameters, {'page': 1, 'per_page': 20});
        return {
          'data': [
            _notificationJson,
            {..._notificationJson, 'id': 'n2'}
          ],
        };
      };

      final result = await service.fetchNotifications();
      expect(result, hasLength(2));
      expect(result.first.id, 'n1');
      expect(result.first.title, 'Test');
      expect(result.first.isRead, isFalse);
    });

    test('fetchNotifications forwards page number', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(queryParameters!['page'], 3);
        return {'data': []};
      };

      await service.fetchNotifications(page: 3);
    });

    test('fetchUnreadCount returns count', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/notifications/unread-count');
        return {
          'data': {'unread_count': 7}
        };
      };

      final count = await service.fetchUnreadCount();
      expect(count, 7);
    });

    test('fetchUnreadCount returns 0 when null', () async {
      mock.onGet = (path, {queryParameters}) async {
        return {'data': {}};
      };

      final count = await service.fetchUnreadCount();
      expect(count, 0);
    });

    test('markAsRead calls correct path via put', () async {
      mock.onPut = (path, data) async {
        expect(path, '/notifications/n1/read');
        expect(data, <String, dynamic>{});
        return {};
      };

      await service.markAsRead('n1');
    });

    test('markAllAsRead calls correct path via put', () async {
      mock.onPut = (path, data) async {
        expect(path, '/notifications/read-all');
        expect(data, <String, dynamic>{});
        return {};
      };

      await service.markAllAsRead();
    });
  });

  group('ApiBannerService', () {
    late MockApiClient mock;
    late ApiBannerService service;

    setUp(() {
      mock = MockApiClient();
      service = ApiBannerService(mock);
    });

    test('fetchActiveBanners parses banners', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/banners/active');
        return {
          'data': [_bannerJson],
        };
      };

      final banners = await service.fetchActiveBanners();
      expect(banners, hasLength(1));
      expect(banners.first.id, 'b1');
      expect(banners.first.image, '/api/v1/uploads/banner.jpg');
      expect(banners.first.linkType, 'offer');
      expect(banners.first.title, 'Banner');
    });

    test('fetchActiveBanners with forceRefresh invalidates cache', () async {
      mock.onGet = (path, {queryParameters}) async {
        return {'data': []};
      };

      await service.fetchActiveBanners(forceRefresh: true);
      expect(mock.lastInvalidatedPath, '/banners/active');
    });

    test('fetchActiveBanners without forceRefresh does not invalidate',
        () async {
      mock.onGet = (path, {queryParameters}) async {
        return {'data': []};
      };

      await service.fetchActiveBanners(forceRefresh: false);
      expect(mock.lastInvalidatedPath, isNull);
    });

    test('fetchActiveBanners skips malformed banners', () async {
      mock.onGet = (path, {queryParameters}) async {
        return {
          'data': [
            _bannerJson,
            {'broken': true},
            {..._bannerJson, 'id': 'b2'},
          ],
        };
      };

      final banners = await service.fetchActiveBanners();
      expect(banners, hasLength(2));
      expect(banners[0].id, 'b1');
      expect(banners[1].id, 'b2');
    });

    test('trackClick posts to correct path', () async {
      mock.onPost = (path, data) async {
        expect(path, '/banners/b1/click');
        expect(data, isNull);
        return {};
      };

      await service.trackClick('b1');
    });

    test('fetchActiveBanners returns empty list for empty data', () async {
      mock.onGet = (path, {queryParameters}) async {
        return {'data': []};
      };

      final banners = await service.fetchActiveBanners();
      expect(banners, isEmpty);
    });
  });

  group('ApiFavoritesService', () {
    late MockApiClient mock;
    late ApiFavoritesService service;

    setUp(() {
      mock = MockApiClient();
      service = ApiFavoritesService(mock);
    });

    test('fetchFavorites parses offers', () async {
      mock.onGet = (path, {queryParameters}) async {
        expect(path, '/favorites');
        expect(queryParameters, {'per_page': 100});
        return {
          'data': [_offerJson],
        };
      };

      final offers = await service.fetchFavorites();
      expect(offers, hasLength(1));
      expect(offers.first.id, 'o1');
      expect(offers.first.title, 'Offer');
    });

    test('fetchFavorites returns empty list', () async {
      mock.onGet = (path, {queryParameters}) async {
        return {'data': []};
      };

      final offers = await service.fetchFavorites();
      expect(offers, isEmpty);
    });

    test('addFavorite posts correct data', () async {
      mock.onPost = (path, data) async {
        expect(path, '/favorites');
        expect(data, {'offer_id': 'o1'});
        return {};
      };

      await service.addFavorite('o1');
    });

    test('removeFavorite calls delete with correct path', () async {
      String? deletedPath;
      mock.onDelete = (path, {data}) async {
        deletedPath = path;
      };

      await service.removeFavorite('o1');
      expect(deletedPath, '/favorites/o1');
    });
  });
}
