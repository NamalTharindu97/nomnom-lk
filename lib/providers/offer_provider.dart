import 'package:flutter/foundation.dart';

import '../models/offer.dart';
import '../providers/locale_provider.dart';
import '../services/api_favorites_service.dart';
import '../services/api_offer_service.dart';
import '../services/connectivity_service.dart';
import '../services/local/favorite_store.dart';
import '../services/local/offer_store.dart';

class OfferProvider extends ChangeNotifier {
  OfferProvider({
    required ApiOfferService offerService,
    required ApiFavoritesService favoritesService,
    required FavoriteStore favoriteStore,
    required OfferStore offerStore,
    required ConnectivityService connectivityService,
  })  : _offerService = offerService,
        _favoritesService = favoritesService,
        _favoriteStore = favoriteStore,
        _offerStore = offerStore,
        _connectivityService = connectivityService {
    _connectivityService.onConnectivityChanged.listen((online) {
      _isOnline = online;
      if (online) _syncQueuedActions();
    });
  }

  void setLocaleProvider(LocaleProvider provider) {
    provider.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (_hasLoaded) {
      loadOffers(forceRefresh: true);
    }
  }

  final ApiOfferService _offerService;
  final ApiFavoritesService _favoritesService;
  final FavoriteStore _favoriteStore;
  final OfferStore _offerStore;
  final ConnectivityService _connectivityService;

  bool _isOnline = true;

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
  String? _selectedCuisine;
  int _filterVersion = 0;
  List<Offer>? _cachedFilteredOffers;
  int _cachedFilterVersion = -1;
  List<Offer>? _cachedHotOffers;
  int _cachedHotVersion = -1;

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

  String? get selectedCuisine => _selectedCuisine;

  List<String> get allCuisineTags {
    final tags = <String>{};
    for (final offer in _offers) {
      tags.addAll(offer.cuisineTags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  List<Offer> get filteredOffers {
    if (_cachedFilterVersion == _filterVersion && _cachedFilteredOffers != null) {
      return _cachedFilteredOffers!;
    }
    var results = _offers;
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      results = results.where((offer) {
        return offer.title.toLowerCase().contains(query) ||
            offer.restaurantName.toLowerCase().contains(query);
      }).toList(growable: false);
    }
    if (_selectedCuisine != null) {
      results = results.where((offer) {
        return offer.cuisineTags.contains(_selectedCuisine);
      }).toList(growable: false);
    }
    _cachedFilteredOffers = results;
    _cachedFilterVersion = _filterVersion;
    return _cachedFilteredOffers!;
  }

  List<Offer> get hotOffers {
    if (_cachedHotOffers != null && _cachedHotVersion == _filterVersion) {
      return _cachedHotOffers!;
    }
    final sorted = List<Offer>.from(filteredOffers)
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    _cachedHotOffers = sorted.length > 5 ? sorted.sublist(0, 5) : sorted;
    _cachedHotVersion = _filterVersion;
    return _cachedHotOffers!;
  }

  void filterByCuisine(String? tag) {
    if (_selectedCuisine == tag) return;
    _selectedCuisine = tag;
    _filterVersion++;
    notifyListeners();
  }

  void clearCuisineFilter() {
    if (_selectedCuisine == null) return;
    _selectedCuisine = null;
    _filterVersion++;
    notifyListeners();
  }

  List<Offer> get favoriteOffers {
    return _offers.where((offer) => offer.isFavorite).toList(growable: false);
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
    if (_isOnline) {
      try {
        final result = await _offerService.fetchOffers(page: _currentPage);
        _offers = result.data;
        _rebuildOffersCache();
        _filterVersion++;
        _hasMore = result.hasMore;
        _total = result.total;
        _hasLoaded = true;
        await _offerStore.saveOffersByPage(_currentPage, _offers);
      } catch (e) {
        _error = 'Failed to load offers. Pull to retry.';
      }
    }
    if (!_hasLoaded) {
      final cached = _offerStore.getOffersByPage(_currentPage);
      if (cached != null) {
        _offers = cached;
        _rebuildOffersCache();
        _filterVersion++;
        _hasLoaded = true;
      } else {
        _error = 'No internet connection';
      }
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
      _filterVersion++;
      await _offerStore.saveOffersByPage(_currentPage, _offers);
    } catch (e) {
      debugPrint('Failed to load more offers: $e');
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refreshOffers() async {
    await Future.wait([
      loadOffers(forceRefresh: true),
      loadFavorites(),
    ]);
  }

  Future<void> searchOffers(String query) async {
    if (query.trim().isEmpty) {
      _searchQuery = '';
      _filterVersion++;
      _searchError = null;
      _searchResults = const [];
      _rebuildSearchCache();
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchQuery = query;
    _filterVersion++;
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
    _filterVersion++;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    // Cache-first: apply locally stored favorites instantly
    if (_offers.isNotEmpty) {
      try {
        final cachedIds = _favoriteStore.getFavorites();
        if (cachedIds.isNotEmpty) {
          _offers = _offers.map((offer) {
            return offer.copyWith(isFavorite: cachedIds.contains(offer.id));
          }).toList(growable: false);
          _rebuildOffersCache();
          _filterVersion++;
          _searchResults = _searchResults.map((offer) {
            return offer.copyWith(isFavorite: cachedIds.contains(offer.id));
          }).toList(growable: false);
          _rebuildSearchCache();
          notifyListeners();
        }
      } catch (_) {}
    }

    try {
      final favorites = await _favoritesService.fetchFavorites();
      final favoriteIds = favorites.map((o) => o.id).toSet();
      await _favoriteStore.syncFromRemote(favoriteIds);
      _offers = _offers.map((offer) {
        return offer.copyWith(isFavorite: favoriteIds.contains(offer.id));
      }).toList(growable: false);
      _rebuildOffersCache();
      _filterVersion++;
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

  Future<void> _syncQueuedActions() async {
    await loadFavorites();
  }
}
