import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

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
    final image = ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const _ImageFallback(isLoading: true);
          },
          errorBuilder: (context, error, stackTrace) {
            return const _ImageFallback();
          },
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardElevated,
            AppColors.charcoal,
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
            : const Icon(
                Icons.local_dining_rounded,
                color: AppColors.cream,
                size: 36,
              ),
      ),
    );
  }
}
