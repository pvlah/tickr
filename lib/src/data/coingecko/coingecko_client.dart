import 'package:dio/dio.dart';

/// Thrown by [CoinGeckoClient] when the free-tier rate limit (HTTP 429) is hit,
/// so the UI can show a friendly "slow down" message instead of a raw error.
class RateLimitException implements Exception {
  const RateLimitException();
  @override
  String toString() => 'CoinGecko rate limit reached. Please wait a moment.';
}

/// Low-level HTTP access to CoinGecko's public REST API.
///
/// This is the ONLY place `dio` and CoinGecko URLs appear. Repositories call
/// these methods and map the raw JSON into domain entities. Keeping the client
/// "dumb" (returns `dynamic` JSON, no business logic) makes it trivial to mock.
class CoinGeckoClient {
  CoinGeckoClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.coingecko.com/api/v3',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'accept': 'application/json'},
            ),
          );

  final Dio _dio;

  /// `GET /coins/markets` for a specific set of coin ids (the watchlist).
  /// Returns the raw decoded JSON list.
  Future<List<dynamic>> fetchMarkets(List<String> ids) async {
    if (ids.isEmpty) return const [];
    return _get('/coins/markets', {
      'vs_currency': 'usd',
      'ids': ids.join(','),
      'order': 'market_cap_desc',
      'sparkline': 'false',
      'price_change_percentage': '24h',
    });
  }

  /// `GET /coins/markets` for the top coins by market cap — powers the
  /// "add coins" browser.
  Future<List<dynamic>> fetchTopMarkets({int perPage = 50}) {
    return _get('/coins/markets', {
      'vs_currency': 'usd',
      'order': 'market_cap_desc',
      'per_page': '$perPage',
      'page': '1',
      'sparkline': 'false',
      'price_change_percentage': '24h',
    });
  }

  /// `GET /coins/{id}/market_chart` — historical prices for the detail chart.
  /// Returns the `prices` array: a list of `[timestampMs, price]` pairs.
  Future<List<dynamic>> fetchMarketChart(String id, {int days = 7}) async {
    final data = await _getMap('/coins/$id/market_chart', {
      'vs_currency': 'usd',
      'days': '$days',
    });
    return (data['prices'] as List<dynamic>?) ?? const [];
  }

  Future<List<dynamic>> _get(String path, Map<String, dynamic> query) async {
    try {
      final res = await _dio.get<List<dynamic>>(path, queryParameters: query);
      return res.data ?? const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> _getMap(
    String path,
    Map<String, dynamic> query,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return res.data ?? const {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Object _mapError(DioException e) {
    if (e.response?.statusCode == 429) return const RateLimitException();
    return Exception('Network error: ${e.message ?? e.type.name}');
  }
}
