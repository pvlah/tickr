/// A crypto coin as the rest of the app cares about it.
///
/// This is a DOMAIN ENTITY: a clean, API-agnostic value object. The UI and
/// portfolio logic depend on *this*, never on CoinGecko's JSON. If we ever
/// swap data providers, only the `data/` layer changes — entities stay put.
///
/// It's `immutable` (all fields `final`) with value equality, so Riverpod/
/// Flutter can cheaply tell whether anything actually changed.
class Coin {
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.changePercent24h,
    required this.marketCap,
    required this.marketCapRank,
    required this.high24h,
    required this.low24h,
    required this.totalVolume,
  });

  /// CoinGecko slug, e.g. `bitcoin`. The stable key we use everywhere.
  final String id;

  /// Ticker, e.g. `btc`. Display only — NOT unique (many coins share symbols).
  final String symbol;
  final String name;
  final String imageUrl;
  final double price;

  /// 24h change as a percent, e.g. `0.65` means +0.65%.
  final double changePercent24h;
  final double marketCap;
  final int marketCapRank;
  final double high24h;
  final double low24h;
  final double totalVolume;

  /// Uppercased ticker for display, e.g. `BTC`.
  String get displaySymbol => symbol.toUpperCase();

  bool get isUp => changePercent24h >= 0;

  // FULL value equality: two Coins are equal only if every field matches.
  // This matters for a live-price app — if we keyed equality on `id` alone,
  // a new price wouldn't count as a "change" and the UI wouldn't rebuild.
  // Dart has no auto-generated data classes, which is why production code
  // usually reaches for `equatable` or `freezed` to avoid writing this by
  // hand; we keep it explicit here so the mechanism is visible.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Coin &&
          other.id == id &&
          other.symbol == symbol &&
          other.name == name &&
          other.imageUrl == imageUrl &&
          other.price == price &&
          other.changePercent24h == changePercent24h &&
          other.marketCap == marketCap &&
          other.marketCapRank == marketCapRank &&
          other.high24h == high24h &&
          other.low24h == low24h &&
          other.totalVolume == totalVolume);

  @override
  int get hashCode => Object.hash(
    id,
    symbol,
    name,
    imageUrl,
    price,
    changePercent24h,
    marketCap,
    marketCapRank,
    high24h,
    low24h,
    totalVolume,
  );
}
