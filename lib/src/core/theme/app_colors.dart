import 'package:flutter/material.dart';

/// Design-token: the raw color palette for Tickr.
///
/// We keep *raw* colors here and let [AppTheme] map them onto Flutter's
/// [ColorScheme]/[ThemeData] slots. Widgets should generally read colors from
/// `Theme.of(context).colorScheme.*` rather than referencing these directly,
/// so light/dark mode "just works". The two exceptions are the semantic
/// market colors [up]/[down], which have no ColorScheme slot — those we expose
/// via a [ThemeExtension] (see `app_theme.dart`).
abstract final class AppColors {
  // Brand seed — a confident fintech indigo/violet. ColorScheme.fromSeed
  // derives a full, accessible palette from this single hue.
  static const Color seed = Color(0xFF5B5BD6);

  // Semantic market colors. Green = gains, red = losses. Tuned to stay legible
  // on both light and dark surfaces.
  static const Color up = Color(0xFF16C784); // CoinGecko-ish green
  static const Color down = Color(0xFFEA3943); // CoinGecko-ish red

  // Dark surfaces (our primary/default brand surface — fintech apps lean dark).
  static const Color darkBackground = Color(0xFF0E0F13);
  static const Color darkSurface = Color(0xFF16181F);
  static const Color darkSurfaceVariant = Color(0xFF1E212B);

  // Light surfaces.
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
}
