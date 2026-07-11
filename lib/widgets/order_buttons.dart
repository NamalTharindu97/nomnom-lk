import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/order_link_parser.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';

class OrderButtonsSection extends StatefulWidget {
  final String? orderUrl;
  final String? orderUrlAlt;

  const OrderButtonsSection({
    super.key,
    this.orderUrl,
    this.orderUrlAlt,
  });

  @override
  State<OrderButtonsSection> createState() => _OrderButtonsSectionState();
}

class _OrderButtonsSectionState extends State<OrderButtonsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final urls = <String>[];
    if (widget.orderUrl != null) urls.add(widget.orderUrl!);
    if (widget.orderUrlAlt != null) urls.add(widget.orderUrlAlt!);

    if (urls.isEmpty) return const SizedBox.shrink();

    final hasBoth = urls.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.offerOrderNow,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        if (hasBoth)
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animation,
                curve: const Interval(0, 0.4, curve: Curves.easeOut),
              ),
            ),
            child: Row(
              children: [
                for (int i = 0; i < urls.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 6,
                        right: i == urls.length - 1 ? 0 : 6,
                      ),
                      child: _OrderButton(url: urls[i], t: t),
                  ),
                ),
              ],
            ),
          )
        else
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animation,
                curve: const Interval(0, 0.4, curve: Curves.easeOut),
              ),
            ),
            child: _OrderButton(url: urls.first, t: t),
          ),
      ],
    );
  }
}

class _OrderButton extends StatelessWidget {
  final String url;
  final AppLocalizations t;

  const _OrderButton({
    required this.url,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final type = parseOrderLink(url);
    final color = orderLinkBrandColor(type);
    final label = switch (type) {
      OrderLinkType.uberEats => t.offerOrderUberEats,
      OrderLinkType.pickMe => t.offerOrderPickMe,
      OrderLinkType.unknown => t.offerOrderVia,
    };

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(orderLinkIcon(type), size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
  }
}
