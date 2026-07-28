import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../core/api_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../services/api_platform_service.dart';
import '../utils/spacings.dart';

class OrderButtonsSection extends StatelessWidget {
  final List<PlatformData> platforms;

  const OrderButtonsSection({
    super.key,
    required this.platforms,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (platforms.isEmpty) return const SizedBox.shrink();

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
        for (int i = 0; i < platforms.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacings.xs),
          _PlatformButton(platform: platforms[i]),
        ],
      ],
    );
  }
}

class _PlatformButton extends StatelessWidget {
  final PlatformData platform;

  const _PlatformButton({required this.platform});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(platform.primaryColor);
    final logoUrl = platform.logoUrl;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleTap(context, platform),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (logoUrl != null && logoUrl.isNotEmpty)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        ApiConfig.resolveUrl(logoUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildFallbackBadge(platform),
                      ),
                    ),
                  )
                else
                  _buildFallbackBadge(platform),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    platform.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBadge(PlatformData platform) {
    final initials = platform.displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, PlatformData platform) async {
    final uri = Uri.parse(platform.deepLinkScheme);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (!context.mounted) return;
    _showInstallDialog(context, platform);
  }

  void _showInstallDialog(BuildContext context, PlatformData platform) {
    final storeUrl = platform.slug == 'uber_eats'
        ? (Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.ubercab.eats'
            : 'https://apps.apple.com/app/uber-eats-food-delivery/id1058959277')
        : platform.slug == 'pickme'
            ? (Platform.isAndroid
                ? 'https://play.google.com/store/apps/details?id=com.pickme.pickme'
                : 'https://apps.apple.com/app/pickme/id1196019644')
            : 'https://play.google.com/store/search?q=${Uri.encodeComponent(platform.displayName)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!
            .platformNotInstalled(platform.displayName)),
        content: Text(AppLocalizations.of(context)!
            .platformInstallPrompt(platform.displayName)),
        actionsAlignment: MainAxisAlignment.end,
        actionsOverflowAlignment: OverflowBarAlignment.end,
        actionsOverflowButtonSpacing: Spacings.xs,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.generalCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
            },
            child: Text(AppLocalizations.of(context)!.platformInstall),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return const Color(0xFF06C167);
}
