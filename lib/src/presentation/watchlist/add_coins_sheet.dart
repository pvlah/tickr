import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/coin_tile.dart';
import '../../core/widgets/state_views.dart';
import 'watchlist_controller.dart';

/// Bottom sheet that lists the top coins and lets the user toggle each one on
/// or off the watchlist. Demonstrates reading derived state ([watchlistProvider]
/// membership) and calling Notifier methods from the UI.
class AddCoinsSheet extends ConsumerWidget {
  const AddCoinsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: AddCoinsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both the async list of top coins and the current watchlist ids.
    final topMarkets = ref.watch(topMarketsProvider);
    final watchlist = ref.watch(watchlistProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text('Add coins', style: context.text.titleLarge),
        ),
        Expanded(
          child: topMarkets.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: '$e',
              onRetry: () => ref.invalidate(topMarketsProvider),
            ),
            data: (coins) => ListView.builder(
              itemCount: coins.length,
              itemBuilder: (context, i) {
                final coin = coins[i];
                final inList = watchlist.contains(coin.id);
                return CoinTile(
                  coin: coin,
                  trailing: IconButton(
                    icon: Icon(
                      inList ? Icons.check_circle : Icons.add_circle_outline,
                      color: inList ? context.colors.primary : null,
                    ),
                    onPressed: () =>
                        ref.read(watchlistProvider.notifier).toggle(coin.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
