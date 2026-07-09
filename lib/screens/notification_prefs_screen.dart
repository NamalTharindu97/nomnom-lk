import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';

class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  final _keys = const {
    'new_offers': 'notif_new_offers',
    'price_drops': 'notif_price_drops',
    'openings': 'notif_openings',
  };

  late Map<String, bool> _values;

  @override
  void initState() {
    super.initState();
    _values = {for (final k in _keys.keys) k: true};
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final entry in _keys.entries) {
        _values[entry.key] = prefs.getBool(entry.value) ?? true;
      }
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keys[key]!, value);
    setState(() => _values[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final loc = AppLocalizations.of(context)!;

    final items = [
      (loc.notifPrefsNewOffers, loc.notifPrefsNewOffersDesc, 'new_offers', Icons.local_offer_outlined),
      (loc.notifPrefsPriceDrops, loc.notifPrefsPriceDropsDesc, 'price_drops', Icons.trending_down_rounded),
      (loc.notifPrefsOpenings, loc.notifPrefsOpeningsDesc, 'openings', Icons.storefront_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notifPrefsTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(Spacings.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final (title, desc, key, icon) = items[index];
          return Container(
            padding: const EdgeInsets.fromLTRB(Spacings.md, Spacings.sm + 2, Spacings.xs, Spacings.sm + 2),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.surfaceAlt),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colors.textPrimary, size: 20),
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
                        desc,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _values[key]!,
                  onChanged: (v) => _toggle(key, v),
                  activeColor: AppColors.curry,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
