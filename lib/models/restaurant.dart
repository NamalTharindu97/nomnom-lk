import 'package:flutter/foundation.dart';
import 'social_link.dart';

@immutable
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.slug,
    this.phone,
    required this.description,
    required this.cuisineTags,
    required this.status,
    this.coverImage,
    this.socialLinks = const [],
    this.orderPlatforms = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? phone;
  final String description;
  final List<String> cuisineTags;
  final String status;
  final String? coverImage;
  final List<SocialLink> socialLinks;
  final List<String> orderPlatforms;

  String? get instagramUrl {
    final link = socialLinks.where((l) => l.platform == 'instagram').firstOrNull;
    return link?.url;
  }

  String? get facebookUrl {
    final link = socialLinks.where((l) => l.platform == 'facebook').firstOrNull;
    return link?.url;
  }

  String? get websiteUrl {
    final link = socialLinks.where((l) => l.platform == 'website').firstOrNull;
    return link?.url;
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      phone: json['phone'] as String?,
      description: json['description'] as String? ?? '',
      cuisineTags:
          (json['cuisine_tags'] as List?)?.cast<String>() ?? [],
      status: json['status'] as String? ?? 'approved',
      coverImage: json['cover_image'] as String?,
      socialLinks: SocialLink.listFromJson(json['social_links'] as List?),
      orderPlatforms: (json['order_platforms'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'phone': phone,
      'description': description,
      'cuisine_tags': cuisineTags,
      'status': status,
      'cover_image': coverImage,
      'social_links': SocialLink.listToJson(socialLinks),
      'order_platforms': orderPlatforms,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? slug,
    String? phone,
    String? description,
    List<String>? cuisineTags,
    String? status,
    String? coverImage,
    List<SocialLink>? socialLinks,
    List<String>? orderPlatforms,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      cuisineTags: cuisineTags ?? this.cuisineTags,
      status: status ?? this.status,
      coverImage: coverImage ?? this.coverImage,
      socialLinks: socialLinks ?? this.socialLinks,
      orderPlatforms: orderPlatforms ?? this.orderPlatforms,
    );
  }
}
