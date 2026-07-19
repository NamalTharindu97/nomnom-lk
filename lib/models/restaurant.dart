import 'package:flutter/foundation.dart';

@immutable
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.slug,
    required this.address,
    this.phone,
    required this.description,
    required this.cuisineTags,
    required this.status,
    this.coverImage,
    this.instagramUrl,
    this.facebookUrl,
    this.websiteUrl,
    this.orderPlatforms = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String address;
  final String? phone;
  final String description;
  final List<String> cuisineTags;
  final String status;
  final String? coverImage;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? websiteUrl;
  final List<String> orderPlatforms;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
      description: json['description'] as String? ?? '',
      cuisineTags:
          (json['cuisine_tags'] as List?)?.cast<String>() ?? [],
      status: json['status'] as String? ?? 'approved',
      coverImage: json['cover_image'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      orderPlatforms: (json['order_platforms'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'address': address,
      'phone': phone,
      'description': description,
      'cuisine_tags': cuisineTags,
      'status': status,
      'cover_image': coverImage,
      'instagram_url': instagramUrl,
      'facebook_url': facebookUrl,
      'website_url': websiteUrl,
      'order_platforms': orderPlatforms,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? slug,
    String? address,
    String? phone,
    String? description,
    List<String>? cuisineTags,
    String? status,
    String? coverImage,
    String? instagramUrl,
    String? facebookUrl,
    String? websiteUrl,
    List<String>? orderPlatforms,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      cuisineTags: cuisineTags ?? this.cuisineTags,
      status: status ?? this.status,
      coverImage: coverImage ?? this.coverImage,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      orderPlatforms: orderPlatforms ?? this.orderPlatforms,
    );
  }
}
