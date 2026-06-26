import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/portfolio.dart';

/// Local persistence boundary for the portfolio + watchlist.
///
/// An interface (not a concrete class) so the app uses a Hive-backed
/// implementation while tests use a no-op one — no Hive init needed in tests.
/// We persist plain JSON strings, which sidesteps Hive TypeAdapters/codegen
/// entirely (a deliberate simplicity tradeoff for a portfolio app).
abstract interface class LocalStore {
  Portfolio? readPortfolio();
  void writePortfolio(Portfolio portfolio);
  List<String>? readWatchlist();
  void writeWatchlist(List<String> ids);
}

/// Default used in tests/widgets where persistence is irrelevant: reads return
/// null (→ defaults kick in), writes are dropped.
class NoopStore implements LocalStore {
  const NoopStore();
  @override
  Portfolio? readPortfolio() => null;
  @override
  void writePortfolio(Portfolio portfolio) {}
  @override
  List<String>? readWatchlist() => null;
  @override
  void writeWatchlist(List<String> ids) {}
}

/// Hive-backed implementation. Stores JSON strings in a single box.
class HiveStore implements LocalStore {
  HiveStore(this._box);
  final Box _box;

  static const _portfolioKey = 'portfolio';
  static const _watchlistKey = 'watchlist';

  @override
  Portfolio? readPortfolio() {
    final raw = _box.get(_portfolioKey);
    if (raw is! String) return null;
    return Portfolio.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  void writePortfolio(Portfolio portfolio) {
    // Fire-and-forget: Hive writes to disk async; the UI doesn't need to wait.
    _box.put(_portfolioKey, jsonEncode(portfolio.toJson()));
  }

  @override
  List<String>? readWatchlist() {
    final raw = _box.get(_watchlistKey);
    if (raw is! String) return null;
    return (jsonDecode(raw) as List).cast<String>();
  }

  @override
  void writeWatchlist(List<String> ids) {
    _box.put(_watchlistKey, jsonEncode(ids));
  }
}

/// Overridden in `main()` with a [HiveStore]; defaults to [NoopStore] so any
/// ProviderScope/ProviderContainer (incl. tests) works without extra setup.
final localStoreProvider = Provider<LocalStore>((ref) => const NoopStore());
