import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/coin_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../domain/entities/coin.dart';
import 'add_coins_sheet.dart';
import 'watchlist_controller.dart';

/// Watchlist tab. A [ConsumerWidget] watches [watchlistMarketsProvider], whose
/// [AsyncValue] we map onto the design-system Loading/Empty/Error/data states.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsAsync = ref.watch(watchlistMarketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add coins',
            onPressed: () => AddCoinsSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        // Pull-to-refresh: invalidate the provider so it refetches.
        onRefresh: () async {
          ref.invalidate(watchlistMarketsProvider);
          await ref.read(watchlistMarketsProvider.future);
        },
        // `.when` is AsyncValue's exhaustive matcher — one branch per state.
        child: marketsAsync.when(
          loading: () => const LoadingView(message: 'Loading prices…'),
          error: (e, _) => _errorScroll(
            ErrorView(
              message: '$e',
              onRetry: () => ref.invalidate(watchlistMarketsProvider),
            ),
          ),
          data: (coins) => coins.isEmpty
              ? _errorScroll(_emptyState(context))
              : _CoinList(coins: coins),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) => EmptyView(
        icon: Icons.bookmark_border,
        title: 'Your watchlist is empty',
        subtitle: 'Add a coin to track its live price and 24h change.',
        action: Builder(
          builder: (context) => FilledButton.icon(
            onPressed: () => AddCoinsSheet.show(context),
            icon: const Icon(Icons.add),
            label: const Text('Add coins'),
          ),
        ),
      );

  // RefreshIndicator needs a *scrollable* child to drive the pull gesture, so
  // wrap non-list states in a full-height scroll view.
  Widget _errorScroll(Widget child) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      );
}

class _CoinList extends ConsumerWidget {
  const _CoinList({required this.coins});

  final List<Coin> coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: coins.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
      itemBuilder: (context, i) {
        final coin = coins[i];
        return Dismissible(
          key: ValueKey(coin.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            color: context.colors.errorContainer,
            child: Icon(Icons.delete_outline, color: context.colors.onErrorContainer),
          ),
          onDismissed: (_) =>
              ref.read(watchlistProvider.notifier).remove(coin.id),
          child: CoinTile(
            coin: coin,
            onTap: () {/* Day 3: navigate to detail */},
          ),
        );
      },
    );
  }
}
