import 'package:flutter/foundation.dart';

@immutable
class Offer {
  const Offer({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantSlug,
    required this.title,
    this.titleSi,
    this.titleTa,
    required this.description,
    this.descriptionSi,
    this.descriptionTa,
    required this.originalPrice,
    required this.offerPrice,
    required this.imageUrls,
    required this.location,
    required this.endDate,
    this.cuisineTags = const [],
    this.isFavorite = false,
    this.distanceKm,
  });

  final String id;
  final String restaurantId;
  final String restaurantName;
  final String restaurantSlug;
  final String title;
  final String? titleSi;
  final String? titleTa;
  final String description;
  final String? descriptionSi;
  final String? descriptionTa;
  final double originalPrice;
  final double offerPrice;
  final List<String> imageUrls;
  final String location;
  final DateTime endDate;
  final List<String> cuisineTags;
  final bool isFavorite;
  final double? distanceKm;

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';
  double get saving => originalPrice - offerPrice;

  double get discountPercent {
    if (originalPrice <= 0) return 0;
    return ((saving / originalPrice) * 100).clamp(0, 100);
  }

  String get discountLabel {
    if (discountPercent > 0) return '${discountPercent.round()}% off';
    return 'Rs. ${saving.round()} off';
  }

  String localizedTitle(String locale) {
    if (locale == 'si' && titleSi != null && titleSi!.isNotEmpty) return titleSi!;
    if (locale == 'ta' && titleTa != null && titleTa!.isNotEmpty) return titleTa!;
    return title;
  }

  String localizedDescription(String locale) {
    if (locale == 'si' && descriptionSi != null && descriptionSi!.isNotEmpty) return descriptionSi!;
    if (locale == 'ta' && descriptionTa != null && descriptionTa!.isNotEmpty) return descriptionTa!;
    return description;
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      restaurantId: json['restaurant']['id'] as String,
      restaurantName: json['restaurant']['name'] as String,
      restaurantSlug: json['restaurant']['slug'] as String,
      title: json['title'] as String,
      titleSi: json['title_si'] as String?,
      titleTa: json['title_ta'] as String?,
      description: json['description'] as String? ?? '',
      descriptionSi: json['description_si'] as String?,
      descriptionTa: json['description_ta'] as String?,
      originalPrice: (json['original_price'] as num).toDouble(),
      offerPrice: (json['offer_price'] as num).toDouble(),
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      cuisineTags: (json['restaurant']['cuisine_tags'] as List?)?.cast<String>() ?? [],
      location: json['restaurant']['address'] as String? ?? '',
      endDate: DateTime.parse(json['end_date'] as String),
      isFavorite: json['is_favorited'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_si': titleSi,
      'title_ta': titleTa,
      'description': description,
      'description_si': descriptionSi,
      'description_ta': descriptionTa,
      'original_price': originalPrice,
      'offer_price': offerPrice,
      'image_urls': imageUrls,
      'end_date': endDate.toIso8601String(),
      'is_favorited': isFavorite,
      'distance_km': distanceKm,
      'restaurant': {
        'id': restaurantId,
        'name': restaurantName,
        'slug': restaurantSlug,
        'cuisine_tags': cuisineTags,
        'address': location,
      },
    };
  }

  Offer copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? restaurantSlug,
    String? title,
    String? titleSi,
    String? titleTa,
    String? description,
    String? descriptionSi,
    String? descriptionTa,
    double? originalPrice,
    double? offerPrice,
    List<String>? imageUrls,
    List<String>? cuisineTags,
    String? location,
    DateTime? endDate,
    bool? isFavorite,
    double? distanceKm,
  }) {
    return Offer(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantSlug: restaurantSlug ?? this.restaurantSlug,
      title: title ?? this.title,
      titleSi: titleSi ?? this.titleSi,
      titleTa: titleTa ?? this.titleTa,
      description: description ?? this.description,
      descriptionSi: descriptionSi ?? this.descriptionSi,
      descriptionTa: descriptionTa ?? this.descriptionTa,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      imageUrls: imageUrls ?? this.imageUrls,
      cuisineTags: cuisineTags ?? this.cuisineTags,
      location: location ?? this.location,
      endDate: endDate ?? this.endDate,
      isFavorite: isFavorite ?? this.isFavorite,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
