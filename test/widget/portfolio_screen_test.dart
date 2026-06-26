import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/src/core/theme/app_theme.dart';
import 'package:tickr/src/domain/entities/coin.dart';
import 'package:tickr/src/presentation/markets/live_prices.dart';
import 'package:tickr/src/presentation/portfolio/portfolio_controller.dart';
import 'package:tickr/src/presentation/portfolio/portfolio_screen.dart';

Coin _btc(double price) => Coin(
  id: 'bitcoin',
  symbol: 'btc',
  name: 'Bitcoin',
  imageUrl: '',
  price: price,
  changePercent24h: 0,
  marketCap: 0,
  marketCapRank: 0,
  high24h: 0,
  low24h: 0,
  totalVolume: 0,
);

void main() {
  testWidgets('portfolio reflects a buy and shows live P&L', (tester) async {
    // Live prices: BTC now $150. We'll buy at $100, so expect +50% / +$50.
    final container = ProviderContainer(
      overrides: [
        livePricesProvider.overrideWith(
          (ref) => Stream.value({'bitcoin': _btc(150)}),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Execute a real buy through the Notifier → domain logic.
    container
        .read(portfolioProvider.notifier)
        .buy(coin: _btc(100), quantity: 1, price: 100);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const PortfolioScreen()),
      ),
    );
    await tester.pump(); // let the stream emit

    // Holding is shown...
    expect(find.text('Bitcoin'), findsOneWidget);
    // ...with the live unrealized gain (+$50.00 and +50.00%).
    expect(
      find.textContaining('+50.00%'),
      findsWidgets,
      reason: 'holding should show +50% unrealized P&L',
    );
    // Net worth = 99,900 cash + 150 holdings = 100,050.
    expect(find.textContaining('100,050'), findsOneWidget);
  });
}
