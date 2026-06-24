import 'package:flutter/foundation.dart';

import '../models/offer.dart';
import '../services/favorites_service.dart';
import '../services/mock_offer_service.dart';

class OfferProvider extends ChangeNotifier {
  OfferProvider({
    required MockOfferService offerService,
    required FavoritesService favoritesService,
  })  : _offerService = offerService,
        _favoritesService = favoritesService;

  final MockOfferService _offerService;
  final FavoritesService _favoritesService;

  List<Offer> _offers = const [];
  Set<String> _favoriteIds = <String>{};
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<Offer> get offers => List.unmodifiable(_offers);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String get searchQuery => _searchQuery;

  List<Offer> get favoriteOffers {
    return _offers.where((offer) => offer.isFavorite).toList(growable: false);
  }

  List<Offer> get filteredOffers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return offers;
    }

    return _offers.where((offer) {
      return offer.foodName.toLowerCase().contains(query) ||
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
    final results = await _offerService.fetchOffers();
    _favoriteIds = await _favoritesService.loadFavoriteIds();
    _offers = _applyFavorites(results);
    _hasLoaded = true;
    _setLoading(false);
  }

  Future<void> refreshOffers() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await loadOffers(forceRefresh: true);
  }

  Future<void> toggleFavorite(String offerId) async {
    if (_favoriteIds.contains(offerId)) {
      _favoriteIds.remove(offerId);
    } else {
      _favoriteIds.add(offerId);
    }

    _offers = _applyFavorites(_offers);
    notifyListeners();
    await _favoritesService.saveFavoriteIds(_favoriteIds);
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    notifyListeners();
  }

  List<Offer> _applyFavorites(List<Offer> offers) {
    return offers
        .map(
          (offer) => offer.copyWith(
            isFavorite: _favoriteIds.contains(offer.id),
          ),
        )
        .toList(growable: false);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }
}
