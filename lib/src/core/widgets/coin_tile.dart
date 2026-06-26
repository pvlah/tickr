import 'package:flutter/material.dart';

import '../../domain/entities/coin.dart';
import '../format/formatters.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'change_badge.dart';

/// One row in a coin list: logo, name/symbol, price, and a 24h [ChangeBadge].
/// Reused by the watchlist and the "add coins" browser, with [trailing]
/// letting each context swap in its own action (chevron vs. add/remove toggle).
class CoinTile extends StatelessWidget {
  const CoinTile({
    super.key,
    required this.coin,
    this.onTap,
    this.trailing,
  });

  final Coin coin;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: _CoinLogo(url: coin.imageUrl, symbol: coin.displaySymbol),
      title: Text(coin.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleMedium),
      subtitle: Text(coin.displaySymbol, style: context.text.bodySmall),
      trailing: trailing ??
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.usd(coin.price),
                  style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              ChangeBadge(changePercent: coin.changePercent24h),
            ],
          ),
    );
  }
}

/// Network logo with a graceful fallback to the ticker initials.
class _CoinLogo extends StatelessWidget {
  const _CoinLogo({required this.url, required this.symbol});

  final String url;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: context.colors.surfaceContainerHighest,
      child: ClipOval(
        child: Image.network(
          url,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Text(
            symbol.isNotEmpty ? symbol.characters.first : '?',
            style: context.text.labelLarge,
          ),
        ),
      ),
    );
  }
}
