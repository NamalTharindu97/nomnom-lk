import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/context_colors.dart';
import '../utils/spacings.dart';

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
  });

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
      ),
    );
  }
}

class OfferCardShimmer extends StatelessWidget {
  const OfferCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.surface,
      highlightColor: context.colors.surfaceAlt,
      child: Container(
        height: 280,
        margin: const EdgeInsets.fromLTRB(Spacings.md, 0, Spacings.md, Spacings.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacings.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonBlock(width: 180, height: 14),
                  const SizedBox(height: Spacings.xs),
                  const _SkeletonBlock(width: 120, height: 12),
                  const SizedBox(height: Spacings.xs),
                  Row(
                    children: [
                      const _SkeletonBlock(width: 16, height: 12),
                      const SizedBox(width: 6),
                      const _SkeletonBlock(width: 100, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfferShimmerList extends StatelessWidget {
  const OfferShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(3, (index) => const OfferCardShimmer()),
      ),
    );
  }
}

class RestaurantCardShimmer extends StatelessWidget {
  const RestaurantCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.surface,
      highlightColor: context.colors.surfaceAlt,
      child: Container(
        height: 100,
        margin: const EdgeInsets.fromLTRB(Spacings.md, 0, Spacings.md, Spacings.sm),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Row(
            children: [
              const _SkeletonCircle(size: 44),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _SkeletonBlock(width: 140, height: 14),
                    const SizedBox(height: Spacings.xs),
                    const _SkeletonBlock(width: 200, height: 12),
                    const SizedBox(height: Spacings.xs),
                    const _SkeletonBlock(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HotOfferShimmer extends StatelessWidget {
  const HotOfferShimmer({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.surface,
      highlightColor: context.colors.surfaceAlt,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.sm + 2, Spacings.sm - 2,
                Spacings.sm + 2, Spacings.sm - 2,
              ),
              child: const _SkeletonBlock(width: 90, height: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantShimmerList extends StatelessWidget {
  const RestaurantShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(4, (index) => const RestaurantCardShimmer()),
      ),
    );
  }
}
