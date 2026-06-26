import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/market_providers.dart';
import '../../domain/entities/coin.dart';
import '../../domain/portfolio_valuation.dart';
import '../portfolio/portfolio_controller.dart';
import '../watchlist/watchlist_controller.dart';

/// How often live prices re-poll. 20s stays well under CoinGecko's free-tier
/// rate limit while still feeling "live".
const _pollInterval = Duration(seconds: 20);

/// Every coin id we need a live price for = watchlist ∪ portfolio holdings.
/// Deriving this means we poll ONE batched request instead of two.
final trackedIdsProvider = Provider<List<String>>((ref) {
  final watchlist = ref.watch(watchlistProvider);
  final held = ref.watch(portfolioProvider).holdings.keys;
  return {...watchlist, ...held}.toList();
});

/// THE single live price feed: a [Stream] of `coinId → Coin`, re-polled on a
/// timer. Both the watchlist and the portfolio derive from this, so there's one
/// source of truth and one network cadence.
///
/// Lifecycle: emits immediately, then every [_pollInterval]; rebuilds when the
/// tracked ids change; cancels its timer and closes the controller on dispose.
final livePricesProvider = StreamProvider<Map<String, Coin>>((ref) {
  final ids = ref.watch(trackedIdsProvider);
  final repo = ref.watch(marketRepositoryProvider);

  final controller = StreamController<Map<String, Coin>>();

  Future<void> tick() async {
    try {
      final coins = await repo.getMarkets(ids, forceRefresh: true);
      controller.add({for (final c in coins) c.id: c});
    } catch (e, st) {
      controller.addError(e, st);
    }
  }

  tick();
  final timer = Timer.periodic(_pollInterval, (_) => tick());
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Live market data for the watchlist, in the user's chosen order.
/// Derived from [livePricesProvider]; `whenData` maps the price map through
/// without losing the loading/error wrapper the UI already handles.
final watchlistMarketsProvider = Provider<AsyncValue<List<Coin>>>((ref) {
  final ids = ref.watch(watchlistProvider);
  final pricesAsync = ref.watch(livePricesProvider);
  return pricesAsync.whenData(
    (prices) => [for (final id in ids) if (prices[id] != null) prices[id]!],
  );
});

/// Live valuation of the whole portfolio. Recomputes whenever the portfolio
/// changes OR a new price tick arrives — this is the "P&L updates live" feature.
///
/// Returns a plain value (not AsyncValue): an all-cash portfolio is worth its
/// cash with no prices needed, and holdings fall back to cost basis until the
/// first tick lands — so the balance card never blinks a spinner.
final portfolioValuationProvider = Provider<PortfolioValuation>((ref) {
  final portfolio = ref.watch(portfolioProvider);
  final prices = ref.watch(livePricesProvider).asData?.value ?? const {};
  return PortfolioValuation.from(
    portfolio,
    {for (final e in prices.entries) e.key: e.value.price},
  );
});
