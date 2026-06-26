import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/coin_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../domain/entities/coin.dart';
import '../markets/live_prices.dart';
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
        // Pull-to-refresh: rebuild the shared price stream so it re-polls and
        // re-emits immediately. The derived watchlist updates with it.
        onRefresh: () async {
          ref.invalidate(livePricesProvider);
          await ref.read(livePricesProvider.future);
        },
        child: _body(context, ref, marketsAsync),
      ),
    );
  }

  /// Stream-resilient state mapping: because prices re-poll on a timer, we keep
  /// showing the last good list during refreshes and even on a transient error
  /// tick. We only fall back to the full-screen loading/error views when we
  /// have NO data yet (the very first load).
  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Coin>> async,
  ) {
    final coins = async.asData?.value;
    if (coins != null) {
      return coins.isEmpty
          ? _errorScroll(_emptyState(context))
          : _CoinList(coins: coins);
    }
    if (async.isLoading) {
      return const LoadingView(message: 'Loading prices…');
    }
    return _errorScroll(
      ErrorView(
        message: '${async.error}',
        onRetry: () => ref.invalidate(livePricesProvider),
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
            onTap: () => context.push(Routes.coinDetail(coin.id)),
          ),
        );
      },
    );
  }
}
