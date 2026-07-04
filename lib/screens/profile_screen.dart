import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/spacings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

            return ListView(
              padding: const EdgeInsets.fromLTRB(Spacings.lg, 18, Spacings.lg, Spacings.xxl),
              children: [
                const SizedBox(height: 8),
                _ProfileHeader(user: user),
                const SizedBox(height: 28),
                _StatsRow(user: user),
                const SizedBox(height: 28),
                _MenuSection(user: user),
                const SizedBox(height: 32),
                _SignOutButton(
                  isGuest: user.isGuest,
                  isLoading: authProvider.isLoading,
                  onSignOut: () => _signOut(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return Column(
      children: [
        Stack(
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
              child: Center(
                child: Text(
                  user.name.isEmpty ? '?' : user.name.substring(0, 1).toUpperCase(),
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.background,
                    fontWeight: FontWeight.w900,
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
                    color: AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          user.name,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
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
          padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.curry.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            user.isGuest
                ? 'Guest'
                : switch (user.role) {
                    'admin' => 'Admin',
                    'restaurant_owner' => 'Restaurant Owner',
                    _ => 'Foodie',
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
  const _StatsRow({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Selector<OfferProvider, int>(
      selector: (_, provider) => provider.favoriteOffers.length,
      builder: (context, favoriteCount, child) {
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.chili,
                value: '$favoriteCount',
                label: 'Saved',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.storefront_rounded,
                iconColor: AppColors.ocean,
                value: '-',
                label: 'Restaurants',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.lime,
                value: user.isGuest ? '-' : '1m',
                label: 'Member',
              ),
            ),
          ],
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
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return Container(
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
            style: textTheme.labelSmall?.copyWith(
              color: context.colors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.user});

  final AppUser user;

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
            title: 'My Favorites',
            subtitle: 'Saved deals',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.home, arguments: 2),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.storefront_rounded,
            iconColor: AppColors.ocean,
            title: 'Browse Restaurants',
            subtitle: 'View all restaurants',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.restaurants),
          ),
          _MenuDivider(),
          _ThemeTile(),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.muted,
            title: 'About',
            subtitle: 'Version 1.0.0',
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm + 2),
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
                themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
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
                    'Theme',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    themeProvider.isDark ? 'Dark mode' : 'Light mode',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggle(),
              activeColor: AppColors.curry,
              activeTrackColor: AppColors.curry.withValues(alpha: 0.4),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm + 2),
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
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
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
          isGuest ? 'Sign In' : 'Sign Out',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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
