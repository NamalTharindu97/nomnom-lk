import 'package:flutter/foundation.dart';

@immutable
class SocialLink {
  const SocialLink({
    required this.platform,
    required this.url,
  });

  final String platform;
  final String url;

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      platform: json['platform'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'url': url,
    };
  }

  static List<SocialLink> listFromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json.map((e) => SocialLink.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<Map<String, dynamic>> listToJson(List<SocialLink> links) {
    return links.map((e) => e.toJson()).toList();
  }
}
