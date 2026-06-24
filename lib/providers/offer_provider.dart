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
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSearching = false;

  List<Offer> get offers => List.unmodifiable(_offers);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

  List<Offer> get favoriteOffers {
    return _offers.where((offer) => offer.isFavorite).toList(growable: false);
  }

  List<Offer> get filteredOffers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return offers;
    }
    return _offers.where((offer) {
      return offer.title.toLowerCase().contains(query) ||
          offer.restaurantName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Offer? offerById(String id) {
    for (final offer in _offers) {
      if (offer.id == id) {
        return offer;
      }
    }
    return null;
  }

  Future<void> loadOffers({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) {
      return;
    }
    _setLoading(true);
    try {
      _offers = await _offerService.fetchOffers();
      _hasLoaded = true;
    } catch (e) {
      debugPrint('Failed to load offers: $e');
    }
    _setLoading(false);
  }

  Future<void> refreshOffers() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await loadOffers(forceRefresh: true);
  }

  Future<void> searchOffers(String query) async {
    if (query.trim().isEmpty) {
      _searchQuery = '';
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchQuery = query;
    notifyListeners();
    try {
      _offers = await _offerService.fetchOffers(query: query);
    } catch (_) {
      // Keep existing results on error
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String offerId) async {
    final index = _offers.indexWhere((o) => o.id == offerId);
    if (index == -1) return;

    final wasFavorite = _offers[index].isFavorite;
    _offers[index] = _offers[index].copyWith(isFavorite: !wasFavorite);
    notifyListeners();

    try {
      if (wasFavorite) {
        await _favoritesService.removeFavorite(offerId);
      } else {
        await _favoritesService.addFavorite(offerId);
      }
    } catch (_) {
      _offers[index] = _offers[index].copyWith(isFavorite: wasFavorite);
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }
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
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }
}
