import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../utils/spacings.dart';

enum OrderPlatform {
  uberEats,
  pickMe,
}

OrderPlatform? parsePlatform(String value) {
  return switch (value) {
    'uber_eats' => OrderPlatform.uberEats,
    'pickme' => OrderPlatform.pickMe,
    _ => null,
  };
}

Color _platformColor(OrderPlatform platform) {
  return switch (platform) {
    OrderPlatform.uberEats => const Color(0xFF000000),
    OrderPlatform.pickMe => const Color(0xFFDA291C),
  };
}

Color _platformAccent(OrderPlatform platform) {
  return switch (platform) {
    OrderPlatform.uberEats => const Color(0xFF06C167),
    OrderPlatform.pickMe => const Color(0xFFFFC72C),
  };
}

String _platformUri(OrderPlatform platform) {
  return switch (platform) {
    OrderPlatform.uberEats => 'ubereats://',
    OrderPlatform.pickMe => 'pickme://',
  };
}

class OrderButtonsSection extends StatelessWidget {
  final List<String> platforms;

  const OrderButtonsSection({
    super.key,
    required this.platforms,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final parsed = platforms
        .map(parsePlatform)
        .whereType<OrderPlatform>()
        .toList();

    if (parsed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_cart_rounded, size: 18, color: AppColors.curry),
            const SizedBox(width: Spacings.xs),
            Text(
              t.offerOrderNow,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        for (int i = 0; i < parsed.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacings.xs),
          _PlatformButton(platform: parsed[i], t: t),
        ],
      ],
    );
  }
}

class _PlatformButton extends StatelessWidget {
  final OrderPlatform platform;
  final AppLocalizations t;

  const _PlatformButton({
    required this.platform,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (platform) {
      OrderPlatform.uberEats => t.offerOrderUberEats,
      OrderPlatform.pickMe => t.offerOrderPickMe,
    };
    final brandColor = _platformColor(platform);
    final accent = _platformAccent(platform);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: brandColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final uri = Uri.parse(_platformUri(platform));
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.offerNoAppFound)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _BrandLogo(platform: platform),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final OrderPlatform platform;

  const _BrandLogo({required this.platform});

  @override
  Widget build(BuildContext context) {
    return switch (platform) {
      OrderPlatform.uberEats => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF06C167),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'UE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
      OrderPlatform.pickMe => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'P',
              style: TextStyle(
                color: Color(0xFFDA291C),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
    };
  }
}
