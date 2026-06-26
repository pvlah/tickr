import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FirebaseAnalytics singleton as a provider (override with a fake in tests).
final analyticsProvider =
    Provider<FirebaseAnalytics>((ref) => FirebaseAnalytics.instance);

/// NavigatorObservers for the router. Wraps the analytics observer behind a
/// provider so tests can override it with `[]` (no Firebase in widget tests).
final navigatorObserversProvider = Provider<List<NavigatorObserver>>((ref) {
  return [FirebaseAnalyticsObserver(analytics: ref.watch(analyticsProvider))];
});

/// A small typed wrapper so feature code logs intent-named events instead of
/// scattering raw `logEvent` calls with stringly-typed names everywhere.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(analyticsProvider)),
);

class AnalyticsService {
  AnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  /// Routes a navigation event to GA4 as a screen_view.
  Future<void> logScreenView(String screen) =>
      _analytics.logScreenView(screenName: screen);

  /// Custom event: a paper trade was executed.
  Future<void> logTrade({
    required String side, // 'buy' | 'sell'
    required String coinId,
    required double usdAmount,
  }) =>
      _analytics.logEvent(
        name: 'paper_trade',
        parameters: {
          'side': side,
          'coin_id': coinId,
          'usd_amount': usdAmount,
        },
      );

  /// Records which watchlist layout variant the user saw (Remote Config A/B).
  Future<void> logWatchlistVariant(String variant) =>
      _analytics.logEvent(
        name: 'watchlist_variant_view',
        parameters: {'variant': variant},
      );
}
