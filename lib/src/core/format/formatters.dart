import 'package:intl/intl.dart';

/// Centralized number/price formatting so the whole app reads consistently.
/// Backed by `intl`'s [NumberFormat], which handles locale-aware grouping
/// (the thousands separators) for free.
abstract final class Formatters {
  static final NumberFormat _usd = NumberFormat.currency(symbol: '\$');
  static final NumberFormat _compact = NumberFormat.compactCurrency(
    symbol: '\$',
  );

  /// `$60,102.00`. Crypto can be sub-cent, so show more precision when tiny.
  static String usd(double value) {
    if (value > 0 && value < 1) {
      return NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 6,
      ).format(value);
    }
    return _usd.format(value);
  }

  /// `$1.20B` — compact form for market cap / volume.
  static String compactUsd(double value) => _compact.format(value);

  /// `+0.65%` / `-1.20%` — always signed so direction is unambiguous.
  static String percent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }
}
