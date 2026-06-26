import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/local_store.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/portfolio.dart';

/// Owns the mutable [Portfolio] state and exposes buy/sell intents.
///
/// All the actual money math lives in the pure [Portfolio] domain object; this
/// Notifier is a thin adapter that swaps `state` for the new immutable value.
/// Keeping logic out of the Notifier is what let us unit-test P&L with no
/// Riverpod/Flutter in the loop.
///
/// Day 4 (persistence) overrides [build] to hydrate from Hive and persists on
/// every change — the buy/sell API stays identical.
class PortfolioNotifier extends Notifier<Portfolio> {
  @override
  Portfolio build() {
    // Hydrate from local storage; fall back to a fresh $100k portfolio.
    return ref.read(localStoreProvider).readPortfolio() ?? Portfolio.initial();
  }

  void buy({required Coin coin, required double quantity, required double price}) {
    state = state.buy(coin: coin, quantity: quantity, price: price);
    _persist();
  }

  void sell({required String coinId, required double quantity, required double price}) {
    state = state.sell(coinId: coinId, quantity: quantity, price: price);
    _persist();
  }

  void reset() {
    state = Portfolio.initial();
    _persist();
  }

  void _persist() => ref.read(localStoreProvider).writePortfolio(state);
}

final portfolioProvider =
    NotifierProvider<PortfolioNotifier, Portfolio>(PortfolioNotifier.new);
