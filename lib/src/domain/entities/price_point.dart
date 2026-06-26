/// A single (time, price) sample from a coin's historical chart.
/// Domain entity — the chart widget depends on this, not on CoinGecko's
/// `[timestampMs, price]` array shape.
class PricePoint {
  const PricePoint({required this.time, required this.price});

  final DateTime time;
  final double price;
}
