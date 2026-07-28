import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/offer.dart';
import 'package:nomnom_lk/models/paginated_response.dart';
import 'package:nomnom_lk/providers/offer_provider.dart';
import '../helpers/mocks.dart';

class _FailingOfferService extends MockApiOfferService {
  _FailingOfferService() : super(offers: const []);

  @override
  Future<PaginatedResponse<Offer>> fetchOffers({
    String? query,
    int page = 1,
  }) async {
    throw Exception('Network error');
  }
}

class _MultiPageOfferService extends MockApiOfferService {
  final List<List<Offer>> _pages;

  _MultiPageOfferService({required List<List<Offer>> pages})
      : _pages = pages,
        super(offers: const []);

  @override
  Future<PaginatedResponse<Offer>> fetchOffers({
    String? query,
    int page = 1,
  }) async {
    final idx = page - 1;
    if (idx < 0 || idx >= _pages.length) {
      return PaginatedResponse(
        data: [],
        page: page,
        perPage: 20,
        total: 0,
        totalPages: _pages.length,
      );
    }
    return PaginatedResponse(
      data: _pages[idx],
      page: page,
      perPage: 20,
      total: _pages.fold<int>(0, (sum, p) => sum + p.length),
      totalPages: _pages.length,
    );
  }
}

class _FailingFavoritesService extends MockApiFavoritesService {
  @override
  Future<void> addFavorite(String offerId) async {
    throw Exception('API error');
  }

  @override
  Future<void> removeFavorite(String offerId) async {
    throw Exception('API error');
  }
}

class _CachedOfferStore extends MockOfferStore {
  final List<Offer> _cached;

  _CachedOfferStore(this._cached);

  @override
  List<Offer>? getOffersByPage(int page) => _cached;
}

class _ControlledOfferSearchService extends MockApiOfferService {
  _ControlledOfferSearchService() : super(offers: const []);

  final requests = <String, Completer<PaginatedResponse<Offer>>>{};

  @override
  Future<PaginatedResponse<Offer>> fetchOffers({
    String? query,
    int page = 1,
  }) {
    if (query == null) return super.fetchOffers(page: page);
    return (requests[query] ??= Completer<PaginatedResponse<Offer>>()).future;
  }

  void complete(String query, Offer offer) {
    requests[query]!.complete(PaginatedResponse(
      data: [offer],
      page: 1,
      perPage: 20,
      total: 1,
      totalPages: 1,
    ));
  }
}

OfferProvider _createProvider({
  MockApiOfferService? offerService,
  MockApiFavoritesService? favoritesService,
  MockOfferStore? offerStore,
  MockFavoriteStore? favoriteStore,
  MockConnectivityService? connectivityService,
}) {
  return OfferProvider(
    offerService: offerService ?? MockApiOfferService(),
    favoritesService: favoritesService ?? MockApiFavoritesService(),
    favoriteStore: favoriteStore ?? MockFavoriteStore(),
    offerStore: offerStore ?? MockOfferStore(),
    connectivityService: connectivityService ?? MockConnectivityService(),
  );
}

void main() {
  group('loadOffers', () {
    test('populates offers list from API', () async {
      final offers = [
        makeOffer(id: '1'),
        makeOffer(id: '2', title: 'Offer B'),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      expect(provider.offers, hasLength(2));
      expect(provider.offers[0].id, '1');
      expect(provider.offers[1].title, 'Offer B');
    });

    test('isLoading is false after load completes', () async {
      final provider = _createProvider();

      expect(provider.isLoading, isFalse);

      await provider.loadOffers();

      expect(provider.isLoading, isFalse);
    });

    test('sets error when API fails and no cache available', () async {
      final provider = _createProvider(offerService: _FailingOfferService());

      await provider.loadOffers();

      expect(provider.error, isNotNull);
      expect(provider.error, 'noInternet');
    });

    test('uses cache when API fails but cache has data', () async {
      final cached = [makeOffer(id: 'cached')];
      final provider = _createProvider(
        offerService: _FailingOfferService(),
        offerStore: _CachedOfferStore(cached),
      );

      await provider.loadOffers();

      expect(provider.offers, hasLength(1));
      expect(provider.offers[0].id, 'cached');
      expect(provider.error, 'failedLoadPullRetry');
    });

    test('skips reload when already loaded and no forceRefresh', () async {
      final service = MockApiOfferService(offers: [makeOffer(id: '1')]);
      final provider = _createProvider(offerService: service);

      await provider.loadOffers();
      expect(provider.offers, hasLength(1));

      service.offers.add(makeOffer(id: '2'));

      await provider.loadOffers();

      expect(provider.offers, hasLength(1));
    });

    test('reloads when forceRefresh is true', () async {
      final service = MockApiOfferService(offers: [makeOffer(id: '1')]);
      final provider = _createProvider(offerService: service);

      await provider.loadOffers();
      expect(provider.offers, hasLength(1));

      service.offers.add(makeOffer(id: '2'));

      await provider.loadOffers(forceRefresh: true);

      expect(provider.offers, hasLength(2));
    });
  });

  group('loadMoreOffers', () {
    test('appends new offers from next page', () async {
      final service = _MultiPageOfferService(pages: [
        [makeOffer(id: '1')],
        [makeOffer(id: '2', title: 'Page 2')],
      ]);
      final provider = _createProvider(offerService: service);

      await provider.loadOffers();
      expect(provider.offers, hasLength(1));
      expect(provider.hasMore, isTrue);

      await provider.loadMoreOffers();

      expect(provider.offers, hasLength(2));
      expect(provider.offers[1].id, '2');
      expect(provider.hasMore, isFalse);
    });

    test('does nothing when hasMore is false', () async {
      final service = MockApiOfferService(offers: [makeOffer(id: '1')]);
      final provider = _createProvider(offerService: service);

      await provider.loadOffers();
      expect(provider.hasMore, isFalse);

      await provider.loadMoreOffers();

      expect(provider.offers, hasLength(1));
    });
  });

  group('toggleFavorite', () {
    test('adds favorite optimistically', () async {
      final service = MockApiOfferService(offers: [makeOffer(id: 'fav-1')]);
      final provider = _createProvider(offerService: service);

      await provider.loadOffers();
      expect(provider.favoriteOffers, isEmpty);

      await provider.toggleFavorite('fav-1');

      expect(provider.favoriteOffers, hasLength(1));
      expect(provider.favoriteOffers.first.id, 'fav-1');
    });

    test('removes favorite optimistically', () async {
      final offer = makeOffer(id: 'fav-1').copyWith(isFavorite: true);
      final service = MockApiOfferService(offers: [offer]);
      final provider = _createProvider(offerService: service);

      await provider.loadOffers();
      expect(provider.favoriteOffers, hasLength(1));

      await provider.toggleFavorite('fav-1');

      expect(provider.favoriteOffers, isEmpty);
    });

    test('rolls back on API error', () async {
      final service = MockApiOfferService(offers: [makeOffer(id: 'fail-1')]);
      final provider = _createProvider(
        offerService: service,
        favoritesService: _FailingFavoritesService(),
      );

      await provider.loadOffers();
      expect(provider.favoriteOffers, isEmpty);

      await provider.toggleFavorite('fail-1');

      expect(provider.favoriteOffers, isEmpty);
    });
  });

  group('filterByCuisine', () {
    test('filters offers by cuisine tag', () async {
      final offers = [
        makeOffer(id: '1', cuisine: 'Italian'),
        makeOffer(id: '2', cuisine: 'Chinese'),
        makeOffer(id: '3', cuisine: 'Italian'),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();
      expect(provider.filteredOffers, hasLength(3));

      provider.filterByCuisine('Italian');

      expect(provider.filteredOffers, hasLength(2));
      expect(provider.selectedCuisine, 'Italian');
      expect(
        provider.filteredOffers.every((o) => o.cuisineTags.contains('Italian')),
        isTrue,
      );
    });
  });

  group('clearCuisineFilter', () {
    test('clears filter and shows all offers', () async {
      final offers = [
        makeOffer(id: '1', cuisine: 'Italian'),
        makeOffer(id: '2', cuisine: 'Chinese'),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();
      provider.filterByCuisine('Italian');
      expect(provider.filteredOffers, hasLength(1));

      provider.clearCuisineFilter();

      expect(provider.filteredOffers, hasLength(2));
      expect(provider.selectedCuisine, isNull);
    });
  });

  group('filterByCategory', () {
    test('filters offers by category id', () async {
      final offers = [
        makeOffer(id: '1').copyWith(categoryIds: ['food', 'drinks']),
        makeOffer(id: '2').copyWith(categoryIds: ['drinks']),
        makeOffer(id: '3').copyWith(categoryIds: ['food']),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      provider.filterByCategory('drinks');

      expect(provider.filteredOffers, hasLength(2));
      expect(provider.selectedCategory, 'drinks');
    });
  });

  group('hotOffers', () {
    test('returns top 5 by discount percent descending', () async {
      final offers = List.generate(7, (i) {
        final discountPercent = (i + 1) * 10.0;
        return makeOffer(
          id: 'offer-$i',
          title: 'Offer $i',
          originalPrice: 1000,
          offerPrice: 1000 - (discountPercent / 100 * 1000),
        );
      });
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      expect(provider.hotOffers, hasLength(5));
      expect(provider.hotOffers[0].discountPercent, 70);
      expect(provider.hotOffers[1].discountPercent, 60);
      expect(provider.hotOffers[2].discountPercent, 50);
      expect(provider.hotOffers[3].discountPercent, 40);
      expect(provider.hotOffers[4].discountPercent, 30);
    });
  });

  group('favoriteOffers', () {
    test('returns only favorited offers', () async {
      final offers = [
        makeOffer(id: '1'),
        makeOffer(id: '2').copyWith(isFavorite: true),
        makeOffer(id: '3'),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      expect(provider.favoriteOffers, hasLength(1));
      expect(provider.favoriteOffers.first.id, '2');
    });
  });

  group('offerById', () {
    test('finds correct offer by id', () async {
      final offers = [
        makeOffer(id: 'a', title: 'Offer A'),
        makeOffer(id: 'b', title: 'Offer B'),
        makeOffer(id: 'c', title: 'Offer C'),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      expect(provider.offerById('b')?.title, 'Offer B');
      expect(provider.offerById('nonexistent'), isNull);
    });
  });

  group('allCuisineTags', () {
    test('aggregates unique tags sorted alphabetically', () async {
      final offers = [
        makeOffer(id: '1', cuisine: 'Italian'),
        makeOffer(id: '2', cuisine: 'Chinese'),
        makeOffer(id: '3', cuisine: 'Italian'),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      expect(provider.allCuisineTags, ['Chinese', 'Italian']);
    });
  });

  group('allCategories', () {
    test('aggregates unique category IDs sorted alphabetically', () async {
      final offers = [
        makeOffer(id: '1').copyWith(categoryIds: ['food', 'drinks']),
        makeOffer(id: '2').copyWith(categoryIds: ['drinks', 'desserts']),
        makeOffer(id: '3').copyWith(categoryIds: ['food']),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      expect(provider.allCategories, ['desserts', 'drinks', 'food']);
    });
  });

  group('searchOffers', () {
    test('keeps the newest results when an older search finishes last',
        () async {
      final service = _ControlledOfferSearchService();
      final provider = _createProvider(offerService: service);

      final older = provider.searchOffers('older');
      final newer = provider.searchOffers('newer');
      service.complete('newer', makeOffer(id: 'newer', title: 'Newer'));
      await newer;
      service.complete('older', makeOffer(id: 'older', title: 'Older'));
      await older;

      expect(provider.searchResults.single.id, 'newer');
      expect(provider.isSearching, isFalse);
    });

    test('clearing an active search resets loading state', () async {
      final service = _ControlledOfferSearchService();
      final provider = _createProvider(offerService: service);

      final active = provider.searchOffers('active');
      expect(provider.isSearching, isTrue);
      await provider.searchOffers('');
      expect(provider.isSearching, isFalse);

      service.complete('active', makeOffer(id: 'stale'));
      await active;
      expect(provider.searchResults, isEmpty);
      expect(provider.isSearching, isFalse);
    });

    test('populates searchResults matching the query', () async {
      final offers = [
        makeOffer(id: '1', title: 'Pizza Deal'),
        makeOffer(id: '2', title: 'Burger Combo'),
        makeOffer(id: '3', title: 'Pizza Party'),
      ];
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: offers),
      );

      await provider.loadOffers();

      await provider.searchOffers('Pizza');

      expect(provider.searchResults, hasLength(2));
      expect(
        provider.searchResults
            .every((o) => o.title.toLowerCase().contains('pizza')),
        isTrue,
      );
    });

    test('clears searchResults when query is empty', () async {
      final provider = _createProvider(
        offerService: MockApiOfferService(offers: [makeOffer()]),
      );

      await provider.loadOffers();
      await provider.searchOffers('Test');
      expect(provider.searchResults, isNotEmpty);

      await provider.searchOffers('');

      expect(provider.searchResults, isEmpty);
    });
  });
}
