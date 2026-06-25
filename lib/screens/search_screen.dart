import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/offer_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/offer_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<OfferProvider>().searchOffers(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {});
    context.read<OfferProvider>().searchOffers('');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    autofocus: false,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Food or restaurant name',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<OfferProvider>(
                builder: (context, provider, child) {
                  if (provider.isSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && _controller.text.isNotEmpty) {
                    return EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Search failed',
                      message: provider.error!,
                    );
                  }

                  final offers = provider.offers;

                  if (_controller.text.isNotEmpty && offers.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matching deals',
                      message: 'Try another food or restaurant name.',
                    );
                  }

                  if (offers.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_rounded,
                      title: 'Find your next meal',
                      message: 'Search for food or restaurant names.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return OfferCard(offer: offers[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
