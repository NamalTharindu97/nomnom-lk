import '../../lib/models/banner.dart';
import '../../lib/models/offer.dart';
import '../../lib/models/paginated_response.dart';
import '../../lib/models/restaurant.dart';
import '../../lib/services/api_banner_service.dart';
import '../../lib/services/api_favorites_service.dart';
import '../../lib/services/api_offer_service.dart';
import '../../lib/services/api_restaurant_service.dart';
import '../../lib/services/connectivity_service.dart';
import '../../lib/services/local/favorite_store.dart';
import '../../lib/services/local/offer_store.dart';
import '../../lib/services/local/restaurant_store.dart';

class MockConnectivityService implements ConnectivityService {
  @override
  bool isOnline = true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  Future<bool> checkConnectivity() async => true;

  @override
  void dispose() {}
}

class MockOfferStore implements OfferStore {
  @override
  Future<void> init() async {}

  @override
  List<Offer>? getOffersByPage(int page) => null;

  @override
  Future<void> saveOffersByPage(int page, List<Offer> offers) async {}

  @override
  Future<void> clear() async {}
}

class MockFavoriteStore implements FavoriteStore {
  @override
  Set<String> getFavorites() => {};

  @override
  Future<void> addFavorite(String offerId) async {}

  @override
  Future<void> removeFavorite(String offerId) async {}

  @override
  Future<void> syncFromRemote(Set<String> remoteIds) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> init() async {}
}

class MockRestaurantStore implements RestaurantStore {
  @override
  Future<void> init() async {}

  @override
  List<Restaurant>? getRestaurantsByPage(int page) => null;

  @override
  Future<void> saveRestaurantsByPage(
      int page, List<Restaurant> restaurants) async {}

  @override
  Future<void> clear() async {}
}

Offer makeOffer({
  String id = '1',
  String title = 'Test Offer',
  String restaurantName = 'Test Restaurant',
  double originalPrice = 1000,
  double offerPrice = 600,
  String? cuisine,
}) {
  return Offer(
    id: id,
    restaurantId: 'r1',
    restaurantName: restaurantName,
    restaurantSlug: 'test-restaurant',
    title: title,
    description: 'Test description',
    originalPrice: originalPrice,
    offerPrice: offerPrice,
    imageUrls: [],
    location: 'Colombo',
    endDate: DateTime.now().add(const Duration(days: 7)),
    cuisineTags: cuisine != null ? [cuisine] : [],
  );
}

Restaurant makeRestaurant({
  String id = 'r1',
  String name = 'Test Restaurant',
}) {
  return Restaurant(
    id: id,
    name: name,
    slug: 'test-restaurant',
    address: 'Colombo',
    description: 'Test restaurant description',
    cuisineTags: [],
    status: 'approved',
  );
}

class MockApiOfferService implements ApiOfferService {
  final List<Offer> offers;

  MockApiOfferService({this.offers = const []}) : _results = const [];

  List<Offer> _results;

  @override
  Future<PaginatedResponse<Offer>> fetchOffers(
      {String? query, int page = 1}) async {
    return PaginatedResponse(
      data: query != null && query.isNotEmpty
          ? offers
              .where((o) =>
                  o.title.toLowerCase().contains(query.toLowerCase()) ||
                  o.restaurantName.toLowerCase().contains(query.toLowerCase()))
              .toList()
          : offers,
      page: page,
      perPage: 20,
      total: offers.length,
      totalPages: 1,
    );
  }

  @override
  Future<Offer> getOffer(String id) async {
    return offers.firstWhere((o) => o.id == id);
  }

  @override
  Future<Offer> createOffer(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<PaginatedResponse<Offer>> search({
    required String query,
    int page = 1,
    String? sort,
    String? cuisine,
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    _results = offers
        .where((o) => o.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return PaginatedResponse(
      data: _results,
      page: page,
      perPage: 20,
      total: _results.length,
      totalPages: 1,
    );
  }
}

class MockApiFavoritesService implements ApiFavoritesService {
  MockApiFavoritesService();

  @override
  Future<List<Offer>> fetchFavorites() async => [];

  @override
  Future<void> addFavorite(String offerId) async {}

  @override
  Future<void> removeFavorite(String offerId) async {}
}

class MockApiRestaurantService implements ApiRestaurantService {
  final List<Restaurant> restaurants;

  MockApiRestaurantService({this.restaurants = const []});

  @override
  Future<PaginatedResponse<Restaurant>> fetchRestaurants(
      {String? query, int page = 1}) async {
    return PaginatedResponse(
      data: restaurants,
      page: page,
      perPage: 20,
      total: restaurants.length,
      totalPages: 1,
    );
  }

  @override
  Future<Restaurant> getRestaurant(String id) async {
    return restaurants.firstWhere((r) => r.id == id);
  }
}

class MockApiBannerService implements ApiBannerService {
  MockApiBannerService({List<FeaturedBanner>? banners})
      : banners = banners ?? <FeaturedBanner>[];

  List<FeaturedBanner> banners;
  bool lastForceRefresh = false;

  @override
  Future<List<FeaturedBanner>> fetchActiveBanners(
      {bool forceRefresh = false}) async {
    lastForceRefresh = forceRefresh;
    return List<FeaturedBanner>.from(banners);
  }

  @override
  Future<void> trackClick(String bannerId) async {}
}
