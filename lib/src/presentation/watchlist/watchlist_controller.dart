import 'dart:async';

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

/// How often live prices re-poll. 20s keeps us well under CoinGecko's
/// free-tier rate limit while still feeling "live".
const _pollInterval = Duration(seconds: 20);

/// LIVE market data for the watchlist, as a [Stream].
///
/// A `Future` is ONE async value; a `Stream` is MANY over time — exactly what
/// "prices that keep updating" needs (think RxJS Observable / Swift
/// AsyncSequence). This provider:
///   • emits once immediately, then every [_pollInterval] via [Timer.periodic];
///   • re-watches [watchlistProvider], so changing the list rebuilds the stream
///     (Riverpod disposes the old one and fires [ref.onDispose]);
///   • cancels the timer and closes the controller on dispose — no leaked
///     timers, no setState-after-dispose. This lifecycle hygiene is the whole
///     point of doing it with a StreamController instead of a leaky `async*`.
///
/// The UI sees an [AsyncValue] just like before, so the consumer barely changes
/// — but now it re-renders on every tick.
final watchlistMarketsProvider = StreamProvider<List<Coin>>((ref) {
  final ids = ref.watch(watchlistProvider);
  final repo = ref.watch(marketRepositoryProvider);

  final controller = StreamController<List<Coin>>();

  Future<void> tick() async {
    try {
      controller.add(await repo.getMarkets(ids, forceRefresh: true));
    } catch (e, st) {
      controller.addError(e, st);
    }
  }

  tick(); // emit immediately so the user isn't staring at a spinner.
  final timer = Timer.periodic(_pollInterval, (_) => tick());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Top coins by market cap — powers the "add to watchlist" browser. Independent
/// of the watchlist, so it's a separate fetch.
final topMarketsProvider = FutureProvider<List<Coin>>((ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getTopMarkets(perPage: 50);
});
