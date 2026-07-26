import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/social_link.dart';
import '../services/api_platform_service.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class FollowSection extends StatelessWidget {
  final List<SocialLink> socialLinks;
  final List<SocialPlatformData> platforms;

  const FollowSection({
    super.key,
    this.socialLinks = const [],
    this.platforms = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (socialLinks.isEmpty) return const SizedBox.shrink();

    final t = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.offerFollow,
          style: textTheme.titleMedium?.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          t.offerFollowHint,
          style: textTheme.labelMedium?.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < socialLinks.length; i++) ...[
          _SocialPillButton(
            link: socialLinks[i],
            platform: _findPlatform(socialLinks[i].platform),
            t: t,
          ),
          if (i < socialLinks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  SocialPlatformData? _findPlatform(String slug) {
    return platforms.cast<SocialPlatformData?>().firstWhere(
      (p) => p?.slug == slug,
      orElse: () => null,
    );
  }
}

class _SocialPillButton extends StatelessWidget {
  final SocialLink link;
  final SocialPlatformData? platform;
  final AppLocalizations t;

  const _SocialPillButton({
    required this.link,
    required this.platform,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(platform?.primaryColor ?? '#E38D12');
    final label = platform?.displayName ?? link.platform;
    final logoUrl = platform?.logoUrl;

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            _buildLogo(logoUrl, label, color),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(String? logoUrl, String label, Color color) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(ApiConfig.resolveUrl(logoUrl), fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _fallbackBadge(label, color)),
        ),
      );
    }
    return _fallbackBadge(label, color);
  }

  Widget _fallbackBadge(String label, Color color) {
    final initials = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(initials, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900))),
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
  return AppColors.curry;
}
