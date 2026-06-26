import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// A [ThemeExtension] carrying Tickr's semantic *market* colors (gain/loss).
///
/// Material's [ColorScheme] has no slot for "price went up" green, so we attach
/// our own typed extension to [ThemeData]. Widgets read it via
/// `Theme.of(context).extension<MarketColors>()!` — and because we provide a
/// different instance in the light vs dark theme, it switches automatically.
@immutable
class MarketColors extends ThemeExtension<MarketColors> {
  const MarketColors({required this.up, required this.down});

  final Color up;
  final Color down;

  /// Convenience: pick the right color for a signed change value.
  Color forChange(num change) => change >= 0 ? up : down;

  @override
  MarketColors copyWith({Color? up, Color? down}) =>
      MarketColors(up: up ?? this.up, down: down ?? this.down);

  // [lerp] is required by ThemeExtension so themes can animate between each
  // other. We just interpolate each color.
  @override
  MarketColors lerp(ThemeExtension<MarketColors>? other, double t) {
    if (other is! MarketColors) return this;
    return MarketColors(
      up: Color.lerp(up, other.up, t)!,
      down: Color.lerp(down, other.down, t)!,
    );
  }
}

/// Builds Tickr's light & dark [ThemeData] from the design tokens.
abstract final class AppTheme {
  static const _market = MarketColors(up: AppColors.up, down: AppColors.down);

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // ColorScheme.fromSeed generates a full, WCAG-aware palette from one color.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: brightness,
        ).copyWith(
          surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        );

    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      textTheme: AppTypography.textTheme(base.textTheme),
      extensions: const [_market],
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(
          base.textTheme,
        ).headlineMedium?.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
      ),
    );
  }
}

/// Tiny ergonomic extension so widgets can write `context.market.up`
/// and `context.colors.primary` instead of the verbose `Theme.of(context)...`.
extension ThemeContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  MarketColors get market => Theme.of(this).extension<MarketColors>()!;
}
