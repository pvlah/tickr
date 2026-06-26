import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/src/domain/entities/coin.dart';
import 'package:tickr/src/domain/entities/portfolio.dart';
import 'package:tickr/src/domain/portfolio_valuation.dart';

/// Test helper: a Coin with only the fields the portfolio cares about.
Coin _coin(String id, {String symbol = 'btc', double price = 0}) => Coin(
      id: id,
      symbol: symbol,
      name: id,
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
  final btc = _coin('bitcoin', symbol: 'btc');
  final eth = _coin('ethereum', symbol: 'eth');

  group('Portfolio.buy', () {
    test('starts with \$100k cash and no holdings', () {
      final p = Portfolio.initial();
      expect(p.cash, 100000);
      expect(p.holdings, isEmpty);
    });

    test('buying deducts cash and records the position', () {
      final p = Portfolio.initial().buy(coin: btc, quantity: 0.5, price: 60000);
      expect(p.cash, 100000 - 30000);
      expect(p.holdings['bitcoin']!.quantity, 0.5);
      expect(p.holdings['bitcoin']!.avgCost, 60000);
      expect(p.holdings['bitcoin']!.costBasis, 30000);
    });

    test('buying more averages the cost basis (weighted)', () {
      // 1 @ 100, then 1 @ 200  ->  avg 150 over 2 units.
      final p = Portfolio.initial()
          .buy(coin: btc, quantity: 1, price: 100)
          .buy(coin: btc, quantity: 1, price: 200);
      final h = p.holdings['bitcoin']!;
      expect(h.quantity, 2);
      expect(h.avgCost, 150);
      expect(h.costBasis, 300);
      expect(p.cash, 100000 - 300);
    });

    test('rejects a buy that exceeds available cash', () {
      expect(
        () => Portfolio.initial().buy(coin: btc, quantity: 3, price: 60000),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    test('rejects non-positive quantity', () {
      expect(
        () => Portfolio.initial().buy(coin: btc, quantity: 0, price: 1),
        throwsArgumentError,
      );
    });

    test('is immutable — buy returns a new instance, original unchanged', () {
      final original = Portfolio.initial();
      final after = original.buy(coin: btc, quantity: 1, price: 100);
      expect(original.cash, 100000);
      expect(original.holdings, isEmpty);
      expect(identical(original, after), isFalse);
    });
  });

  group('Portfolio.sell', () {
    test('selling part of a position adds cash, keeps avg cost', () {
      final p = Portfolio.initial()
          .buy(coin: btc, quantity: 2, price: 100) // cash 99800
          .sell(coinId: 'bitcoin', quantity: 1, price: 150); // +150
      final h = p.holdings['bitcoin']!;
      expect(h.quantity, 1);
      expect(h.avgCost, 100); // unchanged on sell
      expect(p.cash, closeTo(99800 + 150, 1e-9));
    });

    test('selling the entire position removes the holding', () {
      final p = Portfolio.initial()
          .buy(coin: btc, quantity: 1, price: 100)
          .sell(coinId: 'bitcoin', quantity: 1, price: 250);
      expect(p.holdings.containsKey('bitcoin'), isFalse);
      expect(p.cash, closeTo(100000 - 100 + 250, 1e-9));
    });

    test('rejects selling more than held', () {
      final p = Portfolio.initial().buy(coin: btc, quantity: 1, price: 100);
      expect(
        () => p.sell(coinId: 'bitcoin', quantity: 2, price: 100),
        throwsA(isA<InsufficientHoldingsException>()),
      );
    });

    test('rejects selling a coin not held', () {
      expect(
        () => Portfolio.initial().sell(coinId: 'dogecoin', quantity: 1, price: 1),
        throwsA(isA<InsufficientHoldingsException>()),
      );
    });
  });

  group('PortfolioValuation (live P&L)', () {
    test('all-cash portfolio is worth exactly the starting balance', () {
      final v = PortfolioValuation.from(Portfolio.initial(), const {});
      expect(v.totalValue, 100000);
      expect(v.totalUnrealizedPnl, 0);
      expect(v.totalReturn, 0);
      expect(v.totalReturnPercent, 0);
    });

    test('computes unrealized gain when price rises above cost', () {
      // Buy 1 BTC @ 100 (cash 99900). Price now 150.
      final p = Portfolio.initial().buy(coin: btc, quantity: 1, price: 100);
      final v = PortfolioValuation.from(p, const {'bitcoin': 150});

      final h = v.holdings.single;
      expect(h.marketValue, 150);
      expect(h.costBasis, 100);
      expect(h.unrealizedPnl, 50);
      expect(h.unrealizedPnlPercent, 50); // +50%
      expect(h.isUp, isTrue);

      expect(v.holdingsValue, 150);
      expect(v.totalValue, closeTo(99900 + 150, 1e-9));
      expect(v.totalUnrealizedPnl, 50);
      // Net worth 100050 vs 100000 start -> +0.05%.
      expect(v.totalReturn, closeTo(50, 1e-9));
      expect(v.totalReturnPercent, closeTo(0.05, 1e-9));
    });

    test('computes unrealized loss when price falls below cost', () {
      final p = Portfolio.initial().buy(coin: eth, quantity: 2, price: 1000);
      final v = PortfolioValuation.from(p, const {'ethereum': 800});
      final h = v.holdings.single;
      expect(h.unrealizedPnl, closeTo(-400, 1e-9)); // (800-1000)*2
      expect(h.unrealizedPnlPercent, closeTo(-20, 1e-9));
      expect(h.isUp, isFalse);
      expect(v.totalUnrealizedPnl, closeTo(-400, 1e-9));
    });

    test('aggregates across multiple holdings', () {
      final p = Portfolio.initial()
          .buy(coin: btc, quantity: 1, price: 100) // cost 100
          .buy(coin: eth, quantity: 1, price: 50); // cost 50
      final v = PortfolioValuation.from(
        p,
        const {'bitcoin': 130, 'ethereum': 40},
      );
      expect(v.totalCost, 150);
      expect(v.holdingsValue, 170); // 130 + 40
      expect(v.totalUnrealizedPnl, 20); // +30 - 10
      // holdings sorted by market value desc: btc(130) before eth(40)
      expect(v.holdings.first.coinId, 'bitcoin');
    });

    test('falls back to cost basis when a price is missing (P&L 0)', () {
      final p = Portfolio.initial().buy(coin: btc, quantity: 1, price: 100);
      final v = PortfolioValuation.from(p, const {}); // no prices
      expect(v.holdings.single.marketValue, 100);
      expect(v.totalUnrealizedPnl, 0);
    });
  });

  group('Portfolio JSON round-trip (persistence)', () {
    test('serializes and restores cash + holdings', () {
      final p = Portfolio.initial()
          .buy(coin: btc, quantity: 1.5, price: 100)
          .buy(coin: eth, quantity: 3, price: 50);
      final restored = Portfolio.fromJson(p.toJson());
      expect(restored.cash, p.cash);
      expect(restored.holdings['bitcoin']!.quantity, 1.5);
      expect(restored.holdings['ethereum']!.avgCost, 50);
    });
  });
}
