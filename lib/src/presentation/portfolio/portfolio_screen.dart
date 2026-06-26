import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Portfolio tab. Day 1: a static "cash balance" hero card to exercise the
/// theme/cards/typography. Day 4 makes the balance & P&L real via a Riverpod
/// Notifier and live prices.
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  // The paper-trading starting balance from the spec.
  static const double startingCash = 100000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _BalanceCard(balance: startingCash),
          const SizedBox(height: AppSpacing.lg),
          Text('Holdings', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No holdings yet. Buy a coin to start paper trading.',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
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
            Text(
              'Total balance',
              style: context.text.labelLarge
                  ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: context.text.headlineMedium?.merge(
                AppTypography.priceFigures.copyWith(color: scheme.onPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Paper trading • \$0.00 (0.00%) today',
              style: context.text.bodyMedium
                  ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
