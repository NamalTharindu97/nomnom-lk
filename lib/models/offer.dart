import 'package:flutter/foundation.dart';

@immutable
class Offer {
  const Offer({
    required this.id,
    required this.restaurantName,
    required this.foodName,
    required this.description,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountLabel,
    required this.imageUrl,
    required this.location,
    this.isFavorite = false,
  });

  final String id;
  final String restaurantName;
  final String foodName;
  final String description;
  final double originalPrice;
  final double offerPrice;
  final String discountLabel;
  final String imageUrl;
  final String location;
  final bool isFavorite;

  Offer copyWith({
    String? id,
    String? restaurantName,
    String? foodName,
    String? description,
    double? originalPrice,
    double? offerPrice,
    String? discountLabel,
    String? imageUrl,
    String? location,
    bool? isFavorite,
  }) {
    return Offer(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      foodName: foodName ?? this.foodName,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      discountLabel: discountLabel ?? this.discountLabel,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  double get saving => originalPrice - offerPrice;

  double get discountPercent {
    if (originalPrice <= 0) {
      return 0;
    }

    return ((saving / originalPrice) * 100).clamp(0, 100).toDouble();
  }
}
