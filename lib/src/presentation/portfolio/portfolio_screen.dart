import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formatters.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/coin.dart';
import '../../domain/portfolio_valuation.dart';
import '../markets/live_prices.dart';
import 'trade_sheet.dart';

/// Portfolio tab: a live net-worth header + holdings with live P&L. Everything
/// here recomputes automatically when [portfolioValuationProvider] re-derives
/// on a price tick or a trade.
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valuation = ref.watch(portfolioValuationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(livePricesProvider);
          await ref.read(livePricesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _BalanceCard(valuation: valuation),
            const SizedBox(height: AppSpacing.lg),
            Text('Holdings', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (valuation.holdings.isEmpty)
              _EmptyHoldings()
            else
              ...valuation.holdings.map((h) => _HoldingTile(valuation: h)),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.valuation});

  final PortfolioValuation valuation;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final returnColor =
        valuation.isUp ? context.market.up : context.market.down;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total balance',
                style: context.text.labelLarge
                    ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.8))),
            const SizedBox(height: AppSpacing.sm),
            Text(
              Formatters.usd(valuation.totalValue),
              style: context.text.headlineMedium?.merge(
                AppTypography.priceFigures.copyWith(color: scheme.onPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${valuation.isUp ? '▲' : '▼'} '
              '${Formatters.usd(valuation.totalReturn.abs())} '
              '(${Formatters.percent(valuation.totalReturnPercent)}) all-time',
              style: context.text.bodyMedium?.copyWith(
                color: returnColor == context.market.up
                    ? scheme.onPrimary
                    : scheme.onPrimary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: AppSpacing.lg, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  label: 'Cash',
                  value: Formatters.usd(valuation.cash),
                  color: scheme.onPrimary,
                ),
                _MiniStat(
                  label: 'Holdings',
                  value: Formatters.usd(valuation.holdingsValue),
                  color: scheme.onPrimary,
                ),
                _MiniStat(
                  label: 'Unrealized P&L',
                  value: Formatters.usd(valuation.totalUnrealizedPnl),
                  color: scheme.onPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: context.text.labelSmall
                ?.copyWith(color: color.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(value,
            style: context.text.titleSmall
                ?.merge(AppTypography.priceFigures.copyWith(color: color))),
      ],
    );
  }
}

class _HoldingTile extends ConsumerWidget {
  const _HoldingTile({required this.valuation});

  final HoldingValuation valuation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = valuation.holding;
    final color = valuation.isUp ? context.market.up : context.market.down;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: context.colors.surfaceContainerHighest,
          child: ClipOval(
            child: Image.network(h.imageUrl, width: 36, height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(h.displaySymbol.characters.first)),
          ),
        ),
        title: Text(h.name, style: context.text.titleMedium),
        subtitle: Text(
          '${h.quantity.toStringAsFixed(4)} ${h.displaySymbol} • avg ${Formatters.usd(h.avgCost)}',
          style: context.text.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Formatters.usd(valuation.marketValue),
                style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text(
              '${Formatters.usd(valuation.unrealizedPnl)} '
              '(${Formatters.percent(valuation.unrealizedPnlPercent)})',
              style: context.text.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        // Tap a holding to trade it. We rebuild a Coin from the holding plus the
        // live price so the sheet has what it needs.
        onTap: () => TradeSheet.show(
          context,
          coin: _coinFromHolding(valuation),
          side: TradeSide.sell,
        ),
      ),
    );
  }

  Coin _coinFromHolding(HoldingValuation v) => Coin(
        id: v.holding.coinId,
        symbol: v.holding.symbol,
        name: v.holding.name,
        imageUrl: v.holding.imageUrl,
        price: v.price,
        changePercent24h: 0,
        marketCap: 0,
        marketCapRank: 0,
        high24h: 0,
        low24h: 0,
        totalVolume: 0,
      );
}

class _EmptyHoldings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No holdings yet. Open a coin and tap Trade to start paper trading.',
          style: context.text.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
