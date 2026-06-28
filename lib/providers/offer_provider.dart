import 'package:flutter/foundation.dart';

import '../models/offer.dart';
import '../services/api_favorites_service.dart';
import '../services/api_offer_service.dart';

class OfferProvider extends ChangeNotifier {
  OfferProvider({
    required ApiOfferService offerService,
    required ApiFavoritesService favoritesService,
  })  : _offerService = offerService,
        _favoritesService = favoritesService;

  final ApiOfferService _offerService;
  final ApiFavoritesService _favoritesService;

  List<Offer> _offers = const [];
  List<Offer> _searchResults = const [];
  Map<String, int> _offerIndex = {};
  Map<String, int> _searchIndex = {};
  List<Offer> _cachedOffers = const [];
  List<Offer> _cachedSearchResults = const [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;
  bool _isSearching = false;
  String? _error;
  String? _searchError;
  int _currentPage = 1;
  bool _hasMore = true;
  int _total = 0;

  List<Offer> get offers => _cachedOffers;
  List<Offer> get searchResults => _cachedSearchResults;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasLoaded => _hasLoaded;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String? get searchError => _searchError;
  bool get hasMore => _hasMore;
  int get total => _total;

  List<Offer> get favoriteOffers {
    return _offers.where((offer) => offer.isFavorite).toList(growable: false);
  }

  List<Offer> get filteredOffers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return offers;
    return _offers.where((offer) {
      return offer.title.toLowerCase().contains(query) ||
          offer.restaurantName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Offer? offerById(String id) {
    final idx = _offerIndex[id];
    if (idx != null && idx < _offers.length) return _offers[idx];
    final sIdx = _searchIndex[id];
    if (sIdx != null && sIdx < _searchResults.length) return _searchResults[sIdx];
    return null;
  }

  void _rebuildOffersCache() {
    _offerIndex = {for (var i = 0; i < _offers.length; i++) _offers[i].id: i};
    _cachedOffers = List.unmodifiable(_offers);
  }

  void _rebuildSearchCache() {
    _searchIndex = {for (var i = 0; i < _searchResults.length; i++) _searchResults[i].id: i};
    _cachedSearchResults = List.unmodifiable(_searchResults);
  }

  Future<void> loadOffers({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) return;
    _setLoading(true);
    _error = null;
    _currentPage = 1;
    try {
      final result = await _offerService.fetchOffers(page: _currentPage);
      _offers = result.data;
      _rebuildOffersCache();
      _hasMore = result.hasMore;
      _total = result.total;
      _hasLoaded = true;
    } catch (e) {
      _error = 'Failed to load offers. Pull to retry.';
    }
    _setLoading(false);
  }

  Future<void> loadMoreOffers() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _currentPage + 1;
      final result = await _offerService.fetchOffers(page: nextPage);
      _hasMore = result.hasMore;
      _currentPage = nextPage;
      _offers = [..._offers, ...result.data];
      _rebuildOffersCache();
    } catch (e) {
      debugPrint('Failed to load more offers: $e');
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refreshOffers() async {
    await loadOffers(forceRefresh: true);
    await loadFavorites();
  }

  Future<void> searchOffers(String query) async {
    if (query.trim().isEmpty) {
      _searchQuery = '';
      _searchError = null;
      _searchResults = const [];
      _rebuildSearchCache();
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchQuery = query;
    _searchError = null;
    notifyListeners();
    try {
      final result = await _offerService.fetchOffers(query: query);
      _searchResults = result.data;
      _rebuildSearchCache();
      _hasMore = result.hasMore;
      _total = result.total;
    } catch (_) {
      _searchError = 'Search failed. Try again.';
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String offerId) async {
    final index = _offerIndex[offerId];
    final sIndex = _searchIndex[offerId];
    final hasOffer = index != null && index < _offers.length;
    final hasSearch = sIndex != null && sIndex < _searchResults.length;
    if (!hasOffer && !hasSearch) return;

    bool wasFavorite = false;
    if (hasOffer) {
      wasFavorite = _offers[index].isFavorite;
      _offers[index] = _offers[index].copyWith(isFavorite: !wasFavorite);
    }
    if (hasSearch) {
      wasFavorite = _searchResults[sIndex].isFavorite;
      _searchResults[sIndex] = _searchResults[sIndex].copyWith(isFavorite: !wasFavorite);
    }

    notifyListeners();

    try {
      if (wasFavorite) {
        await _favoritesService.removeFavorite(offerId);
      } else {
        await _favoritesService.addFavorite(offerId);
      }
    } catch (_) {
      if (hasOffer) {
        _offers[index] = _offers[index].copyWith(isFavorite: wasFavorite);
      }
      if (hasSearch) {
        _searchResults[sIndex] = _searchResults[sIndex].copyWith(isFavorite: wasFavorite);
      }
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    try {
      final favorites = await _favoritesService.fetchFavorites();
      final favoriteIds = favorites.map((o) => o.id).toSet();
      _offers = _offers.map((offer) {
        return offer.copyWith(isFavorite: favoriteIds.contains(offer.id));
      }).toList(growable: false);
      _rebuildOffersCache();
      _searchResults = _searchResults.map((offer) {
        return offer.copyWith(isFavorite: favoriteIds.contains(offer.id));
      }).toList(growable: false);
      _rebuildSearchCache();
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
