import 'package:flutter/material.dart';

/// Design-token: the type scale.
///
/// We build on Flutter's Material 3 [TextTheme] (which already defines roles
/// like `titleLarge`, `bodyMedium`, `labelSmall`) and only tweak weights so
/// numbers/prices read as crisp and tabular. Returning a `TextTheme` lets
/// [AppTheme] merge it into both the light and dark themes.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// A monospaced-ish style for prices so digits don't jitter as values change.
  /// `fontFeatures: [tnum]` enables tabular (fixed-width) figures.
  static const TextStyle priceFigures = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
    fontWeight: FontWeight.w700,
  );
}
