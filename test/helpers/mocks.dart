import '../../lib/models/offer.dart';
import '../../lib/models/paginated_response.dart';
import '../../lib/models/restaurant.dart';
import '../../lib/services/api_favorites_service.dart';
import '../../lib/services/api_offer_service.dart';
import '../../lib/services/api_restaurant_service.dart';

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
  Future<PaginatedResponse<Offer>> fetchOffers({String? query, int page = 1}) async {
    return PaginatedResponse(
      data: query != null && query.isNotEmpty
          ? offers.where((o) =>
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
    _results = offers.where((o) =>
      o.title.toLowerCase().contains(query.toLowerCase())).toList();
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
  Future<PaginatedResponse<Restaurant>> fetchRestaurants({String? query, int page = 1}) async {
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
