import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_providers.dart';
import '../domain/entities/coin.dart';
import '../domain/entities/portfolio.dart';
import '../presentation/portfolio/portfolio_controller.dart';

/// Compile-time demo switch: `flutter run --dart-define=TICKR_DEMO=true`.
///
/// The public web demo is built with this on so a reviewer landing on the link
/// sees a populated, no-friction app: sign-in is bypassed and the portfolio is
/// pre-seeded with a few positions (real cost bases, so live P&L is non-zero).
/// Off by default, so normal builds and tests are unaffected.
const bool kDemoMode = bool.fromEnvironment('TICKR_DEMO');

/// Provider overrides applied only when [kDemoMode] is on.
final demoOverrides = [
  // Skip the sign-in gate.
  isAuthenticatedProvider.overrideWithValue(const AsyncValue.data(true)),
  // Start with a realistic portfolio instead of empty $100k.
  portfolioProvider.overrideWith(_SeededPortfolioNotifier.new),
];

/// A PortfolioNotifier seeded with demo positions (ignores local storage).
class _SeededPortfolioNotifier extends PortfolioNotifier {
  @override
  Portfolio build() {
    return Portfolio.initial()
        .buy(
          coin: _seed('bitcoin', 'btc', 'Bitcoin', 1),
          quantity: 0.8,
          price: 58000,
        )
        .buy(
          coin: _seed('ethereum', 'eth', 'Ethereum', 279),
          quantity: 6,
          price: 2800,
        )
        .buy(
          coin: _seed('solana', 'sol', 'Solana', 4128),
          quantity: 40,
          price: 120,
        );
  }

  /// Minimal Coin with the metadata buy() records (id/symbol/name/logo).
  Coin _seed(String id, String symbol, String name, int imageId) => Coin(
    id: id,
    symbol: symbol,
    name: name,
    imageUrl:
        'https://coin-images.coingecko.com/coins/images/$imageId/large/$id.png',
    price: 0,
    changePercent24h: 0,
    marketCap: 0,
    marketCapRank: 0,
    high24h: 0,
    low24h: 0,
    totalVolume: 0,
  );
}
