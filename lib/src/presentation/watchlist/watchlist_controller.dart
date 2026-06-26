import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/market_providers.dart';
import '../../data/persistence/local_store.dart';
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
  List<String> build() {
    // Restore the saved watchlist, or seed a sensible default on first run.
    return ref.read(localStoreProvider).readWatchlist() ?? _seed;
  }

  bool contains(String id) => state.contains(id);

  void add(String id) {
    if (!state.contains(id)) {
      state = [...state, id];
      _persist();
    }
  }

  void remove(String id) {
    state = state.where((e) => e != id).toList();
    _persist();
  }

  void toggle(String id) => contains(id) ? remove(id) : add(id);

  void _persist() => ref.read(localStoreProvider).writeWatchlist(state);
}

final watchlistProvider =
    NotifierProvider<WatchlistNotifier, List<String>>(WatchlistNotifier.new);

// The live watchlist price feed now lives in `markets/live_prices.dart`
// (`watchlistMarketsProvider`), derived from the shared `livePricesProvider`
// so the watchlist and portfolio share one polling source.

/// Top coins by market cap — powers the "add to watchlist" browser. Independent
/// of the watchlist, so it's a separate fetch.
final topMarketsProvider = FutureProvider<List<Coin>>((ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getTopMarkets(perPage: 50);
});
