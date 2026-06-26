import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FirebaseAnalytics singleton as a provider (override with a fake in tests).
final analyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);

/// NavigatorObservers for the router. Wraps the analytics observer behind a
/// provider so tests can override it with `[]` (no Firebase in widget tests).
final navigatorObserversProvider = Provider<List<NavigatorObserver>>((ref) {
  return [FirebaseAnalyticsObserver(analytics: ref.watch(analyticsProvider))];
});

/// Typed analytics surface. An INTERFACE so feature code depends on intent
/// ("a trade happened") not on FirebaseAnalytics, and tests use [NoopAnalytics]
/// with zero Firebase setup.
abstract interface class AnalyticsService {
  Future<void> logScreenView(String screen);
  Future<void> logTrade({
    required String side,
    required String coinId,
    required double usdAmount,
  });
  Future<void> logWatchlistVariant(String variant);
}

/// Real implementation backed by GA4 via FirebaseAnalytics.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  @override
  Future<void> logScreenView(String screen) =>
      _analytics.logScreenView(screenName: screen);

  @override
  Future<void> logTrade({
    required String side,
    required String coinId,
    required double usdAmount,
  }) => _analytics.logEvent(
    name: 'paper_trade',
    parameters: {'side': side, 'coin_id': coinId, 'usd_amount': usdAmount},
  );

  @override
  Future<void> logWatchlistVariant(String variant) => _analytics.logEvent(
    name: 'watchlist_variant_view',
    parameters: {'variant': variant},
  );
}

/// No-op for tests/previews — satisfies the interface, touches nothing.
class NoopAnalytics implements AnalyticsService {
  const NoopAnalytics();
  @override
  Future<void> logScreenView(String screen) async {}
  @override
  Future<void> logTrade({
    required String side,
    required String coinId,
    required double usdAmount,
  }) async {}
  @override
  Future<void> logWatchlistVariant(String variant) async {}
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseAnalyticsService(ref.watch(analyticsProvider)),
);
