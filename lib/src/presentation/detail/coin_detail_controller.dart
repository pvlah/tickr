import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/market_providers.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/price_point.dart';

/// Live-ish stats for a single coin on the detail screen.
///
/// `.family` makes a provider PARAMETERIZED — here by coin id. Riverpod caches
/// one instance per distinct id, so opening Bitcoin then Ethereum keeps two
/// independent cached results. We reuse the repository's `getMarkets([id])`.
final coinDetailProvider =
    FutureProvider.family<Coin, String>((ref, id) async {
  final repo = ref.watch(marketRepositoryProvider);
  final coins = await repo.getMarkets([id], forceRefresh: true);
  if (coins.isEmpty) {
    throw Exception('No market data for "$id".');
  }
  return coins.first;
});

/// 7-day price series for the chart, parameterized by coin id.
final coinChartProvider =
    FutureProvider.family<List<PricePoint>, String>((ref, id) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getChart(id, days: 7);
});
