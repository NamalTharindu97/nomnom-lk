import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_config.dart';
import '../core/app_routes.dart';
import '../core/app_store.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/context_colors.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/restaurant_provider.dart';
import '../services/api_auth_service.dart';
import '../services/api_client.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/spacings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onNavigateToTab});

  final void Function(int index)? onNavigateToTab;

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().signOut();

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user ?? AppUser.guest();

            return LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth < 360 ? Spacings.md : Spacings.lg,
                  18,
                  constraints.maxWidth < 360 ? Spacings.md : Spacings.lg,
                  Spacings.xxl,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _ProfileHeader(
                              user: user,
                              onEditProfile: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.editProfile)),
                          const SizedBox(height: 28),
                          _StatsRow(
                              user: user, onNavigateToTab: onNavigateToTab),
                          const SizedBox(height: 28),
                          _MenuSection(
                              user: user, onNavigateToTab: onNavigateToTab),
                          const SizedBox(height: 32),
                          _SignOutButton(
                            isGuest: user.isGuest,
                            isLoading: authProvider.isLoading,
                            onSignOut: () => _signOut(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, this.onEditProfile});

  final AppUser user;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final editProfile = user.isLoggedIn && onEditProfile != null
        ? () {
            if (!AppMotion.reduceMotion(context)) {
              HapticFeedback.selectionClick();
            }
            onEditProfile!();
          }
        : null;

    return Column(
      children: [
        GestureDetector(
          onTap: editProfile,
          child: Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.curry,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.curry.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedSwitcher(
                    duration: AppMotion.duration(context, AppMotion.short),
                    child: user.avatarUrl != null
                        ? CachedNetworkImage(
                            key: ValueKey(user.avatarUrl),
                            imageUrl: ApiConfig.resolveUrl(user.avatarUrl!),
                            memCacheWidth:
                                (72 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            key: const ValueKey('avatar-fallback'),
                            child: Text(
                              user.name.isEmpty
                                  ? '?'
                                  : user.name.substring(0, 1).toUpperCase(),
                              style: textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? colors.background
                                    : Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (user.isLoggedIn)
                Positioned(
                  bottom: 0,
                  right: -2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.surfaceAlt, width: 2),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: context.colors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: editProfile,
          child: Text(
            user.name,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (!user.isGuest) ...[
          const SizedBox(height: 4),
          Text(
            user.email,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.curry.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            user.isGuest
                ? AppLocalizations.of(context)!.generalGuest
                : switch (user.role) {
                    'admin' => AppLocalizations.of(context)!.profileAdmin,
                    'restaurant_owner' =>
                      AppLocalizations.of(context)!.profileRestaurantOwner,
                    _ => AppLocalizations.of(context)!.profileFoodie,
                  },
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.curry,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user, this.onNavigateToTab});

  final AppUser user;
  final void Function(int index)? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return Selector<OfferProvider, int>(
      selector: (_, provider) => provider.favoriteOffers.length,
      builder: (context, favoriteCount, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final cardWidth = compact
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 24) / 3;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.chili,
                    value: '$favoriteCount',
                    label: AppLocalizations.of(context)!.profileSaved,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: Consumer<RestaurantProvider>(
                    builder: (context, provider, _) {
                      return _StatCard(
                        icon: Icons.storefront_rounded,
                        iconColor: AppColors.ocean,
                        value: '${provider.total}',
                        label: AppLocalizations.of(context)!.restaurantsTitle,
                        onTap: provider.restaurants.isEmpty
                            ? null
                            : () => Navigator.of(context)
                                .pushNamed(AppRoutes.restaurants),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    icon: Icons.calendar_month_rounded,
                    iconColor: AppColors.lime,
                    value: user.isGuest ? '-' : '1m',
                    label: AppLocalizations.of(context)!.profileMemberSince,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacings.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.surfaceAlt),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: context.colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.user, this.onNavigateToTab});

  final AppUser user;
  final void Function(int index)? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceAlt),
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.chili,
            title: AppLocalizations.of(context)!.profileMyFavorites,
            subtitle: AppLocalizations.of(context)!.profileSavedDeals,
            onTap: onNavigateToTab != null
                ? () => onNavigateToTab!(2)
                : () => Navigator.of(context)
                    .pushNamed(AppRoutes.home, arguments: 2),
          ),
          _MenuDivider(),
          _ThemeTile(),
          _MenuDivider(),
          _LanguageTile(),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.curry,
            title: AppLocalizations.of(context)!.profileNotificationPreferences,
            subtitle: AppLocalizations.of(context)!.profileManageNotifications,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.notificationPrefs),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.edit_outlined,
            iconColor: AppColors.ocean,
            title: AppLocalizations.of(context)!.editProfileTitle,
            subtitle: AppLocalizations.of(context)!.editProfileSubtitle,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.share_outlined,
            iconColor: AppColors.lime,
            title: AppLocalizations.of(context)!.profileShareApp,
            subtitle: AppLocalizations.of(context)!.profileShareAppSubtitle,
            onTap: () => Share.share(
                '${AppLocalizations.of(context)!.profileShareAppMessage}\n${AppStore.storeUrl}'),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.star_outline_rounded,
            iconColor: AppColors.chili,
            title: AppLocalizations.of(context)!.profileRateApp,
            subtitle: AppLocalizations.of(context)!.profileRateAppSubtitle,
            onTap: () async {
              final uri = Uri.parse(AppStore.marketUri);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                final fallback = Uri.parse(AppStore.storeUrl);
                await launchUrl(fallback, mode: LaunchMode.externalApplication);
              }
            },
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.info_outline_rounded,
            iconColor: context.colors.muted,
            title: AppLocalizations.of(context)!.profileAbout,
            subtitle: AppLocalizations.of(context)!.profileVersion,
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: context.colors.textSecondary,
            title: AppLocalizations.of(context)!.profilePrivacyPolicy,
            subtitle:
                AppLocalizations.of(context)!.profilePrivacyPolicySubtitle,
            onTap: () =>
                _openLegalUrl(context, '${ApiConfig.adminUrl}/privacy'),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.description_outlined,
            iconColor: context.colors.textSecondary,
            title: AppLocalizations.of(context)!.profileTermsOfService,
            subtitle:
                AppLocalizations.of(context)!.profileTermsOfServiceSubtitle,
            onTap: () => _openLegalUrl(context, '${ApiConfig.adminUrl}/terms'),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            iconColor: context.colors.textSecondary,
            title: AppLocalizations.of(context)!.profileSupport,
            subtitle: AppLocalizations.of(context)!.profileSupportSubtitle,
            onTap: () =>
                _openLegalUrl(context, '${ApiConfig.adminUrl}/support'),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.delete_outline_rounded,
            iconColor: Colors.red.shade300,
            title: AppLocalizations.of(context)!.profileDeleteAccountWeb,
            subtitle:
                AppLocalizations.of(context)!.profileDeleteAccountWebSubtitle,
            onTap: () =>
                _openLegalUrl(context, '${ApiConfig.adminUrl}/delete-account'),
          ),
          if (!user.isGuest) ...[
            _MenuDivider(),
            _DeleteAccountTile(),
          ],
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final themeProvider = context.watch<ThemeProvider>();

    return InkWell(
      onTap: themeProvider.toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md, vertical: Spacings.sm + 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeProvider.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.curry,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.profileTheme,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    themeProvider.isDark
                        ? AppLocalizations.of(context)!.profileDarkMode
                        : AppLocalizations.of(context)!.profileLightMode,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggle(),
              activeThumbColor: AppColors.curry,
              activeTrackColor: AppColors.curry.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final localeProvider = context.watch<LocaleProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md, vertical: Spacings.sm + 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.translate_rounded,
              color: AppColors.curry,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.languageLabel,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${localeProvider.flag} ${localeProvider.displayName}',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.muted,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (code) {
              localeProvider.setLocale(code);
              context.read<OfferProvider>().loadOffers(forceRefresh: true);
              context
                  .read<RestaurantProvider>()
                  .loadRestaurants(forceRefresh: true);
            },
            itemBuilder: (_) => localeProvider.supportedLocales.map((l) {
              return PopupMenuItem(
                  value: l.code, child: Text('${l.flag}  ${l.name}'));
            }).toList(),
            icon: const Icon(Icons.arrow_drop_down_rounded),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md, vertical: Spacings.sm + 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.muted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Divider(height: 1, color: colors.surfaceAlt, indent: 66);
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({
    required this.isGuest,
    required this.isLoading,
    required this.onSignOut,
  });

  final bool isGuest;
  final bool isLoading;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onSignOut,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(
          isGuest
              ? AppLocalizations.of(context)!.loginSignInButton
              : AppLocalizations.of(context)!.generalLogout,
          style: textTheme.bodyLarge
              ?.copyWith(color: null, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.chili,
          side: BorderSide(color: AppColors.chili.withValues(alpha: 0.3)),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountTile extends StatefulWidget {
  @override
  State<_DeleteAccountTile> createState() => _DeleteAccountTileState();
}

class _DeleteAccountTileState extends State<_DeleteAccountTile> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteAccountTitle),
            content: Text(
              AppLocalizations.of(context)!.deleteAccountConfirmation,
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsOverflowAlignment: OverflowBarAlignment.end,
            actionsOverflowButtonSpacing: Spacings.xs,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.generalCancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final provider = context.read<AuthProvider>();
                  final service = ApiAuthService(
                    context.read<ApiClient>(),
                  );
                  try {
                    await service.requestDeletion();
                    if (!mounted) return;
                    await provider.signOut();
                    if (!mounted) return;
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (_) => false,
                    );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .deleteAccountScheduleError),
                      ),
                    );
                  }
                },
                child: Text(
                  AppLocalizations.of(context)!.generalDelete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md, vertical: Spacings.sm + 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.chili.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.chili, size: 20),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.deleteAccountTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.chili,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.deleteAccountSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.muted),
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

Future<void> _openLegalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.linkOpenError)),
    );
  }
}
