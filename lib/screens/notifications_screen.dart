import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/context_colors.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/empty_state.dart';
import '../widgets/motion_switcher.dart';
import '../widgets/stagger_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationProvider>();
      await provider.loadNotifications();
      if (provider.notifications.isNotEmpty) {
        await provider.markAllAsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacings.md, 18, Spacings.md, Spacings.sm),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Spacings.sm,
                    runSpacing: Spacings.xxs,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.notificationsTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Consumer<NotificationProvider>(
                        builder: (context, provider, child) {
                          if (provider.notifications.isEmpty) {
                            return const SizedBox();
                          }
                          return TextButton(
                            onPressed: () => provider.markAllAsRead(),
                            child: Text(AppLocalizations.of(context)!
                                .notificationsMarkAllRead),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      late final Widget state;
                      if (provider.isLoading) {
                        state = const Center(
                          key: ValueKey('notifications-loading'),
                          child: CircularProgressIndicator(),
                        );
                      } else if (provider.error != null) {
                        state = EmptyState(
                          key: const ValueKey('notifications-error'),
                          icon: Icons.wifi_off_rounded,
                          title:
                              AppLocalizations.of(context)!.generalFailedToLoad,
                          message: provider.error!,
                        );
                      } else if (provider.notifications.isEmpty) {
                        state = EmptyState(
                          key: const ValueKey('notifications-empty'),
                          icon: Icons.notifications_none_rounded,
                          title:
                              AppLocalizations.of(context)!.notificationsEmpty,
                          message: AppLocalizations.of(context)!
                              .notificationsAllCaughtUp,
                        );
                      } else {
                        final notifications = provider.notifications;
                        state = ListView.builder(
                          key: const ValueKey('notifications-list'),
                          padding: const EdgeInsets.only(bottom: Spacings.md),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            return StaggerItem(
                              key: ValueKey('notification-${n.id}'),
                              index: index,
                              child: _NotificationTile(
                                notification: n,
                                onTap: () {
                                  provider.markAsRead(n.id);
                                  if (n.offerId != null &&
                                      n.offerId!.isNotEmpty) {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.offerDetails,
                                      arguments: n.offerId,
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      }
                      return MotionSwitcher(child: state);
                    },
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.short),
        curve: AppMotion.standardCurve,
        padding:
            const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : context.colors.surface.withValues(alpha: 0.5),
          border: Border(
            bottom: BorderSide(
              color: context.colors.surfaceAlt,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.short),
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: Spacings.sm),
              decoration: BoxDecoration(
                color:
                    notification.isRead ? Colors.transparent : AppColors.curry,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: notification.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: Spacings.xxs),
                  Text(
                    notification.body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.colors.muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(context, notification.createdAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.imageUrl != null &&
                notification.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: Spacings.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: ApiConfig.resolveUrl(notification.imageUrl!),
                    width: 48,
                    height: 48,
                    memCacheWidth:
                        (48 * MediaQuery.devicePixelRatioOf(context)).round(),
                    fit: BoxFit.cover,
                    fadeInDuration:
                        AppMotion.duration(context, AppMotion.short),
                    errorWidget: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return loc.notificationsMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return loc.notificationsHoursAgo(diff.inHours);
    if (diff.inDays < 7) return loc.notificationsDaysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}
