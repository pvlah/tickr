import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/market_providers.dart';
import '../../domain/entities/coin.dart';

/// Holds the user's watchlist as an ordered list of CoinGecko ids.
///
/// A [Notifier] is Riverpod's unit of *mutable* state + logic (the modern
/// replacement for StateNotifier/ChangeNotifier). `build()` returns the initial
/// state; methods mutate by REASSIGNING `state` to a new list. We never mutate
/// the existing list in place, because Riverpod compares old vs new by identity
/// to decide who rebuilds — a fresh list guarantees listeners update.
///
/// Day 4 swaps the seeded default for Hive/Firestore persistence; the public
/// API (add/remove/toggle) stays the same, so the UI won't change.
class WatchlistNotifier extends Notifier<List<String>> {
  static const _seed = <String>[
    'bitcoin',
    'ethereum',
    'solana',
    'cardano',
    'dogecoin',
  ];

  @override
  List<String> build() => _seed;

  bool contains(String id) => state.contains(id);

  void add(String id) {
    if (!state.contains(id)) state = [...state, id];
  }

  void remove(String id) {
    state = state.where((e) => e != id).toList();
  }

  void toggle(String id) => contains(id) ? remove(id) : add(id);
}

final watchlistProvider =
    NotifierProvider<WatchlistNotifier, List<String>>(WatchlistNotifier.new);

/// Live market data for the coins currently on the watchlist.
///
/// This is a DERIVED provider: it `ref.watch`es the watchlist ids, so adding or
/// removing a coin automatically re-runs this fetch. A [FutureProvider] models
/// a one-shot async load and exposes an [AsyncValue] (loading / data / error)
/// that the UI pattern-matches onto our Loading/Empty/Error views.
///
/// Day 3 upgrades this to a StreamProvider that re-polls on a timer for live
/// ticking prices.
final watchlistMarketsProvider = FutureProvider<List<Coin>>((ref) async {
  final ids = ref.watch(watchlistProvider);
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getMarkets(ids);
});

/// Top coins by market cap — powers the "add to watchlist" browser. Independent
/// of the watchlist, so it's a separate fetch.
final topMarketsProvider = FutureProvider<List<Coin>>((ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getTopMarkets(perPage: 50);
});
