/// One position in the paper portfolio: how much of a coin you own and what it
/// cost you on average.
///
/// Pure, immutable value object — no Flutter, no network. This is what makes
/// the P&L logic trivially unit-testable.
class Holding {
  const Holding({
    required this.coinId,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.avgCost,
  });

  final String coinId;
  final String symbol;
  final String name;
  final String imageUrl;

  /// Units held (e.g. 0.5 BTC).
  final double quantity;

  /// Average cost basis in USD per unit — the weighted-average price paid.
  final double avgCost;

  /// Total dollars invested in this position.
  double get costBasis => quantity * avgCost;

  String get displaySymbol => symbol.toUpperCase();

  Holding copyWith({double? quantity, double? avgCost}) => Holding(
    coinId: coinId,
    symbol: symbol,
    name: name,
    imageUrl: imageUrl,
    quantity: quantity ?? this.quantity,
    avgCost: avgCost ?? this.avgCost,
  );

  // --- JSON (for Hive persistence on Day 4) ---
  Map<String, dynamic> toJson() => {
    'coinId': coinId,
    'symbol': symbol,
    'name': name,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'avgCost': avgCost,
  };

  factory Holding.fromJson(Map<String, dynamic> json) => Holding(
    coinId: json['coinId'] as String,
    symbol: json['symbol'] as String? ?? '',
    name: json['name'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    quantity: (json['quantity'] as num).toDouble(),
    avgCost: (json['avgCost'] as num).toDouble(),
  );
}
