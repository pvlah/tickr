// Smoke test: with a signed-in user and an empty price feed, the app boots
// into the Watchlist tab and shows the bottom navigation. Firebase is kept
// out of the test via provider overrides.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/src/app.dart';
import 'package:tickr/src/core/analytics/analytics.dart';
import 'package:tickr/src/core/auth/auth_providers.dart';
import 'package:tickr/src/core/remote_config/remote_config.dart';
import 'package:tickr/src/domain/entities/coin.dart';
import 'package:tickr/src/presentation/markets/live_prices.dart';

void main() {
  testWidgets('app boots into the Watchlist tab with bottom nav', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Pretend we're signed in so the router lands on the app, not /signin.
          isAuthenticatedProvider.overrideWithValue(
            const AsyncValue.data(true),
          ),
          // No Firebase analytics observer in tests.
          navigatorObserversProvider.overrideWithValue(const []),
          // No Firebase analytics / remote config in tests.
          analyticsServiceProvider.overrideWithValue(const NoopAnalytics()),
          watchlistLayoutProvider.overrideWithValue(WatchlistLayout.list),
          // Hermetic, empty price feed (watchlist + portfolio derive from it).
          livePricesProvider.overrideWith(
            (ref) => Stream.value(<String, Coin>{}),
          ),
        ],
        child: const TickrApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your watchlist is empty'), findsOneWidget);
    expect(find.text('Watchlist'), findsWidgets);
    expect(find.text('Portfolio'), findsOneWidget);
  });
}
