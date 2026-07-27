import 'package:nomnom_lk/models/app_user.dart';
import 'package:nomnom_lk/models/banner.dart';
import 'package:nomnom_lk/models/notification_model.dart';
import 'package:nomnom_lk/models/offer.dart';
import 'package:nomnom_lk/models/paginated_response.dart';
import 'package:nomnom_lk/models/restaurant.dart';
import 'package:nomnom_lk/services/api_auth_service.dart';
import 'package:nomnom_lk/services/api_banner_service.dart';
import 'package:nomnom_lk/services/api_client.dart';
import 'package:nomnom_lk/services/api_favorites_service.dart';
import 'package:nomnom_lk/services/api_notification_service.dart';
import 'package:nomnom_lk/services/api_offer_service.dart';
import 'package:nomnom_lk/services/api_restaurant_service.dart';
import 'package:nomnom_lk/services/connectivity_service.dart';
import 'package:nomnom_lk/services/local/favorite_store.dart';
import 'package:nomnom_lk/services/local/notification_store.dart';
import 'package:nomnom_lk/services/local/offer_store.dart';
import 'package:nomnom_lk/services/local/restaurant_store.dart';

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

class MockApiClient implements ApiClient {
  Future<Map<String, dynamic>> Function(String,
      {Map<String, dynamic>? queryParameters})? onGet;
  Future<Map<String, dynamic>> Function(String, dynamic)? onPost;
  Future<Map<String, dynamic>> Function(String, dynamic)? onPut;
  Future<void> Function(String, {dynamic data})? onDelete;

  bool clearTokensCalled = false;
  String? lastInvalidatedPath;
  bool cacheCleared = false;

  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    if (onGet != null) return onGet!(path, queryParameters: queryParameters);
    return {};
  }

  @override
  Future<Map<String, dynamic>> post(String path, dynamic data) async {
    if (onPost != null) return onPost!(path, data);
    return {};
  }

  @override
  Future<Map<String, dynamic>> put(String path, dynamic data) async {
    if (onPut != null) return onPut!(path, data);
    return {};
  }

  @override
  Future<void> delete(String path, {dynamic data}) async {
    if (onDelete != null) await onDelete!(path, data: data);
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    Map<String, String>? queryParams,
  }) async {
    return {};
  }

  @override
  Future<void> clearTokens() async {
    clearTokensCalled = true;
  }

  @override
  void invalidateCache(String path) {
    lastInvalidatedPath = path;
  }

  @override
  void clearCache() {
    cacheCleared = true;
  }
}

class MockApiNotificationService implements ApiNotificationService {
  List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool fetchNotificationsThrows = false;
  bool fetchUnreadCountThrows = false;

  @override
  Future<List<AppNotification>> fetchNotifications({int page = 1}) async {
    if (fetchNotificationsThrows) throw Exception('fail');
    return notifications;
  }

  @override
  Future<int> fetchUnreadCount() async {
    if (fetchUnreadCountThrows) throw Exception('fail');
    return unreadCount;
  }

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

class MockNotificationStore implements NotificationStore {
  List<Map<String, dynamic>>? cachedNotifications;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    cachedNotifications = notifications;
  }

  @override
  List<Map<String, dynamic>>? getNotifications() => cachedNotifications;

  @override
  Future<void> clear() async {
    cachedNotifications = null;
  }
}

class MockApiAuthService implements ApiAuthService {
  AppUser? userToReturn;
  Exception? exceptionToThrow;
  bool logoutCalled = false;

  @override
  bool get firebaseAvailable => true;

  @override
  Future<AppUser> signInWithFirebase(String firebaseToken) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }

  @override
  Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return {};
  }

  @override
  Future<void> sendVerificationCode(String email) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }

  @override
  Future<AppUser> verifyEmail(String email, String code) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }

  @override
  Future<Map<String, dynamic>> requestDeletion() async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> cancelDeletion() async {
    return {};
  }

  @override
  Future<AppUser?> restoreUser() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn;
  }
}
