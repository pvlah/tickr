import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/price_point.dart';

/// A 7-day line chart for a coin, built on `fl_chart`'s [LineChart].
///
/// fl_chart wants `List<FlSpot>` (x,y doubles), so we map our domain
/// [PricePoint]s to spots: x = millisecondsSinceEpoch, y = price. The line is
/// colored green/red by the net trend over the window (last vs first price),
/// using the [MarketColors] theme extension.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points});

  final List<PricePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Not enough chart data')),
      );
    }

    final spots = [
      for (final p in points)
        FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.price),
    ];

    final isUp = points.last.price >= points.first.price;
    final lineColor = isUp ? context.market.up : context.market.down;

    // Compute y-bounds with a little padding so the line doesn't touch edges.
    final prices = points.map((p) => p.price);
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.1;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.colors.inverseSurface,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '\$${s.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: context.colors.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.25),
                    lineColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
