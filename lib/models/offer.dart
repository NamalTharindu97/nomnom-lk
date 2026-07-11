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
    this.instagramUrl,
    this.facebookUrl,
    this.websiteUrl,
    this.orderUrl,
    this.orderUrlAlt,
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
  final String? instagramUrl;
  final String? facebookUrl;
  final String? websiteUrl;
  final String? orderUrl;
  final String? orderUrlAlt;

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';
  double get saving => originalPrice - offerPrice;

  double get discountPercent {
    if (originalPrice <= 0) return 0;
    return ((saving / originalPrice) * 100).clamp(0, 100);
  }

  String get discountLabel {
    if (discountPercent > 0) return '${discountPercent.round()}%';
    return '${saving.round()}';
  }

  String discountLabelLocalized(String locale) {
    if (discountPercent > 0) return '${discountPercent.round()}%';
    if (locale == 'si') return 'රු. ${saving.round()}';
    if (locale == 'ta') return 'ரூ. ${saving.round()}';
    return 'Rs. ${saving.round()}';
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
      instagramUrl: (json['restaurant'] as Map<String, dynamic>?)?['instagram_url'] as String?,
      facebookUrl: (json['restaurant'] as Map<String, dynamic>?)?['facebook_url'] as String?,
      websiteUrl: (json['restaurant'] as Map<String, dynamic>?)?['website_url'] as String?,
      orderUrl: (json['restaurant'] as Map<String, dynamic>?)?['order_url'] as String?,
      orderUrlAlt: (json['restaurant'] as Map<String, dynamic>?)?['order_url_alt'] as String?,
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
        'instagram_url': instagramUrl,
        'facebook_url': facebookUrl,
        'website_url': websiteUrl,
        'order_url': orderUrl,
        'order_url_alt': orderUrlAlt,
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
    String? instagramUrl,
    String? facebookUrl,
    String? websiteUrl,
    String? orderUrl,
    String? orderUrlAlt,
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
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      orderUrl: orderUrl ?? this.orderUrl,
      orderUrlAlt: orderUrlAlt ?? this.orderUrlAlt,
    );
  }
}
