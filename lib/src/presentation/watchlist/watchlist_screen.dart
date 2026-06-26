import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/remote_config/remote_config.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/coin_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../domain/entities/coin.dart';
import '../markets/live_prices.dart';
import 'add_coins_sheet.dart';
import 'watchlist_controller.dart';

/// Watchlist tab. Watches [watchlistMarketsProvider] (live prices) and renders
/// one of two layouts chosen by [watchlistLayoutProvider] — a Remote Config
/// A/B test (`list` vs `cards`). It's a [ConsumerStatefulWidget] so it can log
/// which variant the user saw exactly once, in [initState].
class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  @override
  void initState() {
    super.initState();
    // Fire the A/B exposure event once when the screen mounts. ref.read (not
    // watch) — this is a one-shot side effect, not a rebuild trigger.
    final variant = ref.read(watchlistLayoutProvider);
    ref.read(analyticsServiceProvider).logWatchlistVariant(variant.name);
  }

  @override
  Widget build(BuildContext context) {
    final marketsAsync = ref.watch(watchlistMarketsProvider);
    final layout = ref.watch(watchlistLayoutProvider);

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
        child: _body(context, marketsAsync, layout),
      ),
    );
  }

  /// Stream-resilient state mapping: because prices re-poll on a timer, we keep
  /// showing the last good list during refreshes and even on a transient error
  /// tick. We only fall back to the full-screen loading/error views when we
  /// have NO data yet (the very first load).
  Widget _body(
    BuildContext context,
    AsyncValue<List<Coin>> async,
    WatchlistLayout layout,
  ) {
    final coins = async.asData?.value;
    if (coins != null) {
      return coins.isEmpty
          ? _errorScroll(_emptyState(context))
          : _CoinList(coins: coins, layout: layout);
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

/// Renders the watchlist in either A/B variant. Both support swipe-to-remove
/// and tap-to-detail; only the chrome differs (flat divided rows vs. cards).
class _CoinList extends ConsumerWidget {
  const _CoinList({required this.coins, required this.layout});

  final List<Coin> coins;
  final WatchlistLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = layout == WatchlistLayout.cards;
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: cards ? AppSpacing.md : 0,
      ),
      itemCount: coins.length,
      separatorBuilder: (_, _) => cards
          ? const SizedBox(height: AppSpacing.sm)
          : const Divider(
              height: 1,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
            ),
      itemBuilder: (context, i) {
        final coin = coins[i];
        final tile = CoinTile(
          coin: coin,
          onTap: () => context.push(Routes.coinDetail(coin.id)),
        );
        return Dismissible(
          key: ValueKey(coin.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.errorContainer,
              borderRadius: cards ? BorderRadius.circular(AppRadii.lg) : null,
            ),
            child: Icon(
              Icons.delete_outline,
              color: context.colors.onErrorContainer,
            ),
          ),
          onDismissed: (_) =>
              ref.read(watchlistProvider.notifier).remove(coin.id),
          child: cards ? Card(child: tile) : tile,
        );
      },
    );
  }
}
