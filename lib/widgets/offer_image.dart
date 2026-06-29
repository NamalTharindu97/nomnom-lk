import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/api_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';

class OfferImage extends StatelessWidget {
  const OfferImage({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.height,
    this.width,
  });

  final String imageUrl;
  final String? heroTag;
  final BorderRadius borderRadius;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: height,
          width: width,
          child: const _ImageFallback(),
        ),
      );
    }

    final image = ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: CachedNetworkImage(
          imageUrl: ApiConfig.resolveUrl(imageUrl),
          fit: BoxFit.cover,
          placeholder: (context, url) => const _ImageFallback(isLoading: true),
          errorWidget: (context, url, error) => const _ImageFallback(),
        ),
      ),
    );

    if (heroTag == null) {
      return image;
    }

    return Hero(tag: heroTag!, child: image);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.surfaceAlt,
            context.colors.backgroundAlt,
            AppColors.chili,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.local_dining_rounded,
                color: context.colors.textPrimary,
                size: 36,
              ),
      ),
    );
  }
}
