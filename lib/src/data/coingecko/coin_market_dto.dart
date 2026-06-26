import '../../domain/entities/coin.dart';

/// Data Transfer Object for one item from CoinGecko's `/coins/markets` array.
///
/// A DTO's only jobs are (1) parse the raw JSON safely and (2) convert to a
/// domain [Coin]. We parse manually (no codegen) so every field is visible —
/// in a bigger project you'd use json_serializable/freezed to generate this.
///
/// CoinGecko returns nulls for some numeric fields on thin coins, so we coerce
/// defensively with [_toDouble]/[_toInt] instead of trusting the types.
class CoinMarketDto {
  const CoinMarketDto({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.marketCap,
    required this.marketCapRank,
    required this.high24h,
    required this.low24h,
    required this.totalVolume,
  });

  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24h;
  final double marketCap;
  final int marketCapRank;
  final double high24h;
  final double low24h;
  final double totalVolume;

  /// Parse one JSON map. `json` is `Map<String, dynamic>` — Dart's untyped
  /// JSON shape — so we read keys defensively.
  factory CoinMarketDto.fromJson(Map<String, dynamic> json) {
    return CoinMarketDto(
      id: json['id'] as String,
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      currentPrice: _toDouble(json['current_price']),
      priceChangePercentage24h: _toDouble(json['price_change_percentage_24h']),
      marketCap: _toDouble(json['market_cap']),
      marketCapRank: _toInt(json['market_cap_rank']),
      high24h: _toDouble(json['high_24h']),
      low24h: _toDouble(json['low_24h']),
      totalVolume: _toDouble(json['total_volume']),
    );
  }

  /// Map the wire model to the clean domain entity.
  Coin toEntity() => Coin(
        id: id,
        symbol: symbol,
        name: name,
        imageUrl: image,
        price: currentPrice,
        changePercent24h: priceChangePercentage24h,
        marketCap: marketCap,
        marketCapRank: marketCapRank,
        high24h: high24h,
        low24h: low24h,
        totalVolume: totalVolume,
      );

  // JSON numbers can arrive as int or double (or null). Normalize to double.
  static double _toDouble(Object? v) => switch (v) {
        final int i => i.toDouble(),
        final double d => d,
        _ => 0,
      };

  static int _toInt(Object? v) => switch (v) {
        final int i => i,
        final num n => n.toInt(),
        _ => 0,
      };
}
