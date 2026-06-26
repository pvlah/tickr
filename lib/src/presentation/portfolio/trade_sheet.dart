import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/format/formatters.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/coin.dart';
import 'portfolio_controller.dart';

enum TradeSide { buy, sell }

/// Bottom sheet for buying/selling a coin with paper money.
///
/// A [ConsumerStatefulWidget] (vs the stateless ConsumerWidgets elsewhere)
/// because it owns EPHEMERAL UI state — the amount text field and the selected
/// buy/sell side — that shouldn't live in a global provider. It reads the
/// portfolio reactively to validate against cash/holdings and calls the
/// Notifier on confirm.
class TradeSheet extends ConsumerStatefulWidget {
  const TradeSheet({
    super.key,
    required this.coin,
    this.initialSide = TradeSide.buy,
  });

  final Coin coin;
  final TradeSide initialSide;

  static Future<void> show(
    BuildContext context, {
    required Coin coin,
    TradeSide side = TradeSide.buy,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TradeSheet(coin: coin, initialSide: side),
    );
  }

  @override
  ConsumerState<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends ConsumerState<TradeSheet> {
  late TradeSide _side = widget.initialSide;
  final _amountController = TextEditingController();

  Coin get coin => widget.coin;
  double get _price => coin.price;
  double get _usd => double.tryParse(_amountController.text) ?? 0;
  double get _quantity => _price > 0 ? _usd / _price : 0;

  @override
  void dispose() {
    _amountController.dispose(); // controllers must be disposed to avoid leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final held = portfolio.holdings[coin.id]?.quantity ?? 0;
    final maxUsd = _side == TradeSide.buy ? portfolio.cash : held * _price;

    final overLimit = _usd > maxUsd + 1e-6;
    final canSubmit = _usd > 0 && !overLimit && _price > 0;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${coin.name} • ${Formatters.usd(_price)}',
            style: context.text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<TradeSide>(
            segments: const [
              ButtonSegment(value: TradeSide.buy, label: Text('Buy')),
              ButtonSegment(value: TradeSide.sell, label: Text('Sell')),
            ],
            selected: {_side},
            onSelectionChanged: (s) => setState(() => _side = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: '\$ ',
              labelText: 'Amount (USD)',
              helperText: _side == TradeSide.buy
                  ? 'Cash available: ${Formatters.usd(portfolio.cash)}'
                  : 'You hold: ${held.toStringAsFixed(6)} ${coin.displaySymbol}'
                        ' (${Formatters.usd(maxUsd)})',
              errorText: overLimit ? 'Exceeds available' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: maxUsd > 0
                  ? () => setState(
                      () => _amountController.text = maxUsd.toStringAsFixed(2),
                    )
                  : null,
              child: const Text('Max'),
            ),
          ),
          Text(
            '≈ ${_quantity.toStringAsFixed(6)} ${coin.displaySymbol}',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: Text(_side == TradeSide.buy ? 'Buy' : 'Sell'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final notifier = ref.read(portfolioProvider.notifier);
      if (_side == TradeSide.buy) {
        notifier.buy(coin: coin, quantity: _quantity, price: _price);
      } else {
        notifier.sell(coinId: coin.id, quantity: _quantity, price: _price);
      }
      // Fire-and-forget analytics; never block the trade on logging.
      ref
          .read(analyticsServiceProvider)
          .logTrade(
            side: _side == TradeSide.buy ? 'buy' : 'sell',
            coinId: coin.id,
            usdAmount: _usd,
          );
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${_side == TradeSide.buy ? 'Bought' : 'Sold'} '
            '${_quantity.toStringAsFixed(6)} ${coin.displaySymbol}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
