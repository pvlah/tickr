import 'package:flutter/material.dart';

import '../format/formatters.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// A small colored pill showing a signed 24h percentage change.
/// Pulls its green/red from the [MarketColors] theme extension, so it adapts
/// to light/dark automatically.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({super.key, required this.changePercent});

  final double changePercent;

  @override
  Widget build(BuildContext context) {
    final color = context.market.forChange(changePercent);
    final up = changePercent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 1.5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16, color: color),
          Text(
            Formatters.percent(changePercent),
            style: context.text.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
