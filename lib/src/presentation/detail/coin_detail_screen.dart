import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formatters.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/change_badge.dart';
import '../../core/widgets/state_views.dart';
import '../../domain/entities/coin.dart';
import '../portfolio/trade_sheet.dart';
import 'coin_detail_controller.dart';
import 'widgets/price_chart.dart';

/// Detail screen for a single coin: live price header, 7-day chart, key stats.
class CoinDetailScreen extends ConsumerWidget {
  const CoinDetailScreen({super.key, required this.coinId});

  final String coinId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinAsync = ref.watch(coinDetailProvider(coinId));

    return Scaffold(
      appBar: AppBar(title: Text(coinAsync.asData?.value.name ?? coinId)),
      floatingActionButton: coinAsync.asData == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  TradeSheet.show(context, coin: coinAsync.asData!.value),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Trade'),
            ),
      body: coinAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(coinDetailProvider(coinId)),
        ),
        data: (coin) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coinDetailProvider(coinId));
            ref.invalidate(coinChartProvider(coinId));
            await ref.read(coinDetailProvider(coinId).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _PriceHeader(coin: coin),
              const SizedBox(height: AppSpacing.lg),
              _ChartSection(coinId: coinId),
              const SizedBox(height: AppSpacing.lg),
              Text('Stats', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _StatsGrid(coin: coin),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(coin.displaySymbol, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              Formatters.usd(coin.price),
              style: context.text.headlineMedium?.merge(
                AppTypography.priceFigures,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ChangeBadge(changePercent: coin.changePercent24h),
          ],
        ),
      ],
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({required this.coinId});
  final String coinId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(coinChartProvider(coinId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('7-day price', style: context.text.labelLarge),
            const SizedBox(height: AppSpacing.md),
            chartAsync.when(
              loading: () => const SizedBox(height: 220, child: LoadingView()),
              // Compact error that fits the chart's fixed height (the full
              // ErrorView is taller than 220px and would overflow here).
              error: (e, _) => SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 32,
                        color: context.colors.outline,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Couldn't load chart",
                        style: context.text.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(coinChartProvider(coinId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (points) => PriceChart(points: points),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final stats = <(String, String)>[
      ('Market cap', Formatters.compactUsd(coin.marketCap)),
      ('Rank', '#${coin.marketCapRank}'),
      ('24h high', Formatters.usd(coin.high24h)),
      ('24h low', Formatters.usd(coin.low24h)),
      ('24h volume', Formatters.compactUsd(coin.totalVolume)),
    ];
    return Card(
      child: Column(
        children: [
          for (final (i, stat) in stats.indexed) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              dense: true,
              title: Text(stat.$1, style: context.text.bodyMedium),
              trailing: Text(
                stat.$2,
                style: context.text.titleSmall?.merge(
                  AppTypography.priceFigures,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
