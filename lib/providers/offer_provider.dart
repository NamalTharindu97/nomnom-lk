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

  List<Offer> get offers => List.unmodifiable(_offers);
  List<Offer> get searchResults => List.unmodifiable(_searchResults);
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
    for (final offer in _offers) {
      if (offer.id == id) return offer;
    }
    for (final offer in _searchResults) {
      if (offer.id == id) return offer;
    }
    return null;
  }

  Future<void> loadOffers({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) return;
    _setLoading(true);
    _error = null;
    _currentPage = 1;
    try {
      final result = await _offerService.fetchOffers(page: _currentPage);
      _offers = result.data;
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
      _hasMore = result.hasMore;
      _total = result.total;
    } catch (_) {
      _searchError = 'Search failed. Try again.';
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String offerId) async {
    final index = _offers.indexWhere((o) => o.id == offerId);
    final sIndex = _searchResults.indexWhere((o) => o.id == offerId);
    if (index == -1 && sIndex == -1) return;

    bool wasFavorite = false;
    if (index != -1) {
      wasFavorite = _offers[index].isFavorite;
      _offers[index] = _offers[index].copyWith(isFavorite: !wasFavorite);
    }
    if (sIndex != -1) {
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
      if (index != -1) {
        _offers[index] = _offers[index].copyWith(isFavorite: wasFavorite);
      }
      if (sIndex != -1) {
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
      _searchResults = _searchResults.map((offer) {
        return offer.copyWith(isFavorite: favoriteIds.contains(offer.id));
      }).toList(growable: false);
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
