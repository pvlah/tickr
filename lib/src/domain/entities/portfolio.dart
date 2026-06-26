import 'coin.dart';
import 'holding.dart';

/// Raised when a buy would cost more cash than is available.
class InsufficientFundsException implements Exception {
  const InsufficientFundsException({
    required this.required,
    required this.available,
  });
  final double required;
  final double available;
  @override
  String toString() =>
      'Insufficient funds: need \$${required.toStringAsFixed(2)}, '
      'have \$${available.toStringAsFixed(2)}.';
}

/// Raised when a sell exceeds the quantity held.
class InsufficientHoldingsException implements Exception {
  const InsufficientHoldingsException({
    required this.requested,
    required this.held,
  });
  final double requested;
  final double held;
  @override
  String toString() =>
      'Insufficient holdings: tried to sell $requested, hold $held.';
}

/// The paper-trading portfolio: free cash + a set of [Holding]s keyed by coin id.
///
/// IMMUTABLE: [buy] and [sell] return a NEW Portfolio rather than mutating, so
/// the logic is referentially transparent and the state layer just swaps one
/// value for another. All the money math lives here, in pure Dart, so it's
/// covered by fast unit tests with zero Flutter/network setup.
class Portfolio {
  const Portfolio({required this.cash, this.holdings = const {}});

  /// Everyone starts with $100k of (fake) buying power.
  static const double startingCash = 100000;

  factory Portfolio.initial() => const Portfolio(cash: startingCash);

  final double cash;
  final Map<String, Holding> holdings;

  /// Total dollars currently invested at cost (excludes cash).
  double get investedCost =>
      holdings.values.fold(0, (sum, h) => sum + h.costBasis);

  /// Buy [quantity] units of [coin] at [price]/unit.
  ///
  /// Updates the position's weighted-average cost basis:
  ///   newAvg = (oldCostBasis + tradeCost) / newQuantity
  Portfolio buy({
    required Coin coin,
    required double quantity,
    required double price,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be > 0');
    }
    final cost = quantity * price;
    if (cost > cash) {
      throw InsufficientFundsException(required: cost, available: cash);
    }

    final existing = holdings[coin.id];
    final newQuantity = (existing?.quantity ?? 0) + quantity;
    final newAvgCost = ((existing?.costBasis ?? 0) + cost) / newQuantity;

    final updated = Holding(
      coinId: coin.id,
      symbol: coin.symbol,
      name: coin.name,
      imageUrl: coin.imageUrl,
      quantity: newQuantity,
      avgCost: newAvgCost,
    );

    return copyWith(
      cash: cash - cost,
      holdings: {...holdings, coin.id: updated},
    );
  }

  /// Sell [quantity] units of [coinId] at [price]/unit.
  ///
  /// Cost basis of the REMAINING units is unchanged (we don't track realized
  /// P&L separately in this MVP — gains show up as increased cash).
  Portfolio sell({
    required String coinId,
    required double quantity,
    required double price,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be > 0');
    }
    final existing = holdings[coinId];
    if (existing == null || quantity > existing.quantity + _epsilon) {
      throw InsufficientHoldingsException(
        requested: quantity,
        held: existing?.quantity ?? 0,
      );
    }

    final proceeds = quantity * price;
    final remaining = existing.quantity - quantity;
    final newHoldings = {...holdings};
    if (remaining <= _epsilon) {
      newHoldings.remove(coinId); // fully exited the position
    } else {
      newHoldings[coinId] = existing.copyWith(quantity: remaining);
    }

    return copyWith(cash: cash + proceeds, holdings: newHoldings);
  }

  Portfolio copyWith({double? cash, Map<String, Holding>? holdings}) =>
      Portfolio(cash: cash ?? this.cash, holdings: holdings ?? this.holdings);

  // Guard against floating-point dust when comparing/closing positions.
  static const double _epsilon = 1e-10;

  // --- JSON (for Hive persistence) ---
  Map<String, dynamic> toJson() => {
    'cash': cash,
    'holdings': holdings.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final rawHoldings = (json['holdings'] as Map?) ?? const {};
    return Portfolio(
      cash: (json['cash'] as num).toDouble(),
      holdings: rawHoldings.map(
        (k, v) => MapEntry(
          k as String,
          Holding.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
    );
  }
}
