import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/state_views.dart';

/// Watchlist tab. Day 1: a polished placeholder using the design-system's
/// [EmptyView]. Day 2 wires in live CoinGecko prices via Riverpod.
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: EmptyView(
          icon: Icons.bookmark_border,
          title: 'Your watchlist is empty',
          subtitle: 'Search for a coin and add it to track live prices here.',
        ),
      ),
    );
  }
}
