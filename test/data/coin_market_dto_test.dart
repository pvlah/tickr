import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/src/data/coingecko/coin_market_dto.dart';

void main() {
  group('CoinMarketDto.fromJson', () {
    test('parses a well-formed CoinGecko market entry into an entity', () {
      final json = {
        'id': 'bitcoin',
        'symbol': 'btc',
        'name': 'Bitcoin',
        'image': 'https://example.com/btc.png',
        'current_price': 60102,
        'price_change_percentage_24h': 0.65184,
        'market_cap': 1204974978530,
        'market_cap_rank': 1,
        'high_24h': 60592,
        'low_24h': 58320,
        'total_volume': 41202096899,
      };

      final coin = CoinMarketDto.fromJson(json).toEntity();

      expect(coin.id, 'bitcoin');
      expect(coin.displaySymbol, 'BTC');
      expect(coin.price, 60102.0);
      expect(coin.changePercent24h, closeTo(0.65184, 1e-9));
      expect(coin.marketCapRank, 1);
      expect(coin.isUp, isTrue);
    });

    test('coerces ints to doubles and tolerates null numeric fields', () {
      final json = {
        'id': 'thincoin',
        'symbol': 'thn',
        'name': 'Thin Coin',
        // image, price, change etc. all missing/null on thin coins.
        'current_price': null,
        'price_change_percentage_24h': null,
        'market_cap_rank': null,
      };

      final coin = CoinMarketDto.fromJson(json).toEntity();

      expect(coin.price, 0.0);
      expect(coin.changePercent24h, 0.0);
      expect(coin.marketCapRank, 0);
      expect(coin.isUp, isTrue); // 0 counts as non-negative
      expect(coin.imageUrl, '');
    });
  });
}
