class FeaturedBanner {
  final String id;
  final String image;
  final String linkType;
  final String linkValue;
  final String? title;
  final String? sponsorName;

  FeaturedBanner({
    required this.id,
    required this.image,
    required this.linkType,
    required this.linkValue,
    this.title,
    this.sponsorName,
  });

  factory FeaturedBanner.fromJson(Map<String, dynamic> json) {
    return FeaturedBanner(
      id: json['id'] as String,
      image: json['image'] as String,
      linkType: json['link_type'] as String,
      linkValue: json['link_value'] as String,
      title: json['title'] as String?,
      sponsorName: json['sponsor_name'] as String?,
    );
  }
}
