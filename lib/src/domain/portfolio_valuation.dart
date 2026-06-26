import 'entities/holding.dart';
import 'entities/portfolio.dart';

/// A single holding valued at a current market price.
///
/// Pure derived data: given a [Holding] and a [price], every figure below is a
/// computed getter. Nothing here mutates — it's a read-only "view" the UI binds
/// to. This is the unit of "live P&L" that updates every price tick.
class HoldingValuation {
  const HoldingValuation({required this.holding, required this.price});

  final Holding holding;
  final double price;

  String get coinId => holding.coinId;

  /// Current worth of the position.
  double get marketValue => holding.quantity * price;

  /// What it cost.
  double get costBasis => holding.costBasis;

  /// Profit/loss vs cost, in dollars.
  double get unrealizedPnl => marketValue - costBasis;

  /// Profit/loss vs cost, as a percent. Zero cost ⇒ 0% (avoid divide-by-zero).
  double get unrealizedPnlPercent =>
      costBasis == 0 ? 0 : unrealizedPnl / costBasis * 100;

  bool get isUp => unrealizedPnl >= 0;
}

/// Whole-portfolio valuation: cash + every holding valued at market.
class PortfolioValuation {
  const PortfolioValuation({required this.cash, required this.holdings});

  final double cash;
  final List<HoldingValuation> holdings;

  /// Build from a [portfolio] and a map of coinId → current price. Holdings
  /// without a known price fall back to their cost basis (P&L 0) so a missing
  /// tick never shows a wild number.
  factory PortfolioValuation.from(
    Portfolio portfolio,
    Map<String, double> prices,
  ) {
    final valuations = [
      for (final h in portfolio.holdings.values)
        HoldingValuation(holding: h, price: prices[h.coinId] ?? h.avgCost),
    ]..sort((a, b) => b.marketValue.compareTo(a.marketValue));
    return PortfolioValuation(cash: portfolio.cash, holdings: valuations);
  }

  /// Market value of all holdings (excludes cash).
  double get holdingsValue => holdings.fold(0, (sum, h) => sum + h.marketValue);

  /// Cash + holdings — the portfolio's net worth.
  double get totalValue => cash + holdingsValue;

  /// Cost basis across all holdings.
  double get totalCost => holdings.fold(0, (sum, h) => sum + h.costBasis);

  /// Unrealized P&L across holdings (market value − cost), in dollars.
  double get totalUnrealizedPnl => holdingsValue - totalCost;

  double get totalUnrealizedPnlPercent =>
      totalCost == 0 ? 0 : totalUnrealizedPnl / totalCost * 100;

  /// Overall return vs the $100k starting balance (cash gains included).
  double get totalReturn => totalValue - Portfolio.startingCash;

  double get totalReturnPercent => totalReturn / Portfolio.startingCash * 100;

  bool get isUp => totalReturn >= 0;
}
