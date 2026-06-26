import '../../domain/entities/coin.dart';
import '../coingecko/coin_market_dto.dart';
import '../coingecko/coingecko_client.dart';

/// Translates raw CoinGecko JSON into domain [Coin]s and applies a short cache.
///
/// WHY a repository: the presentation layer should ask for "the markets for
/// these coins" without knowing about dio, JSON keys, or HTTP status codes.
/// This class is that seam — it depends on [CoinGeckoClient] (easy to fake in
/// tests) and returns clean entities.
///
/// The [_ttl] cache is important on CoinGecko's free tier (~10–30 calls/min):
/// repeated reads within the window reuse the last response instead of
/// hammering the API.
class MarketRepository {
  MarketRepository(this._client);

  final CoinGeckoClient _client;

  static const Duration _ttl = Duration(seconds: 15);

  final Map<String, _CacheEntry> _cache = {};

  /// Live market data for the given coin ids (the watchlist).
  /// [forceRefresh] bypasses the cache (used by pull-to-refresh).
  Future<List<Coin>> getMarkets(
    List<String> ids, {
    bool forceRefresh = false,
  }) async {
    if (ids.isEmpty) return const [];
    final key = (ids.toList()..sort()).join(',');

    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null && !cached.isStale) return cached.coins;
    }

    final json = await _client.fetchMarkets(ids);
    final coins = _mapList(json);
    _cache[key] = _CacheEntry(coins);
    return coins;
  }

  /// Top coins by market cap, for the "add to watchlist" browser.
  Future<List<Coin>> getTopMarkets({int perPage = 50}) async {
    final json = await _client.fetchTopMarkets(perPage: perPage);
    return _mapList(json);
  }

  List<Coin> _mapList(List<dynamic> json) => json
      .whereType<Map<String, dynamic>>()
      .map((e) => CoinMarketDto.fromJson(e).toEntity())
      .toList();
}

class _CacheEntry {
  _CacheEntry(this.coins) : fetchedAt = DateTime.now();
  final List<Coin> coins;
  final DateTime fetchedAt;
  bool get isStale =>
      DateTime.now().difference(fetchedAt) > MarketRepository._ttl;
}
