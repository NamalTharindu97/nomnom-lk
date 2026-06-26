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
    );
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
    );
  }
}
