// Smoke test: the app boots, renders the watchlist tab, and shows the
// bottom navigation. Real feature tests arrive alongside their features.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/src/app.dart';
import 'package:tickr/src/presentation/watchlist/watchlist_controller.dart';

void main() {
  testWidgets('app boots into the Watchlist tab with bottom nav',
      (WidgetTester tester) async {
    // Override the network-backed provider with empty data so the smoke test
    // is hermetic — no real HTTP, deterministic empty state.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistMarketsProvider.overrideWith((ref) async => []),
        ],
        child: const TickrApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The default route is the Watchlist tab.
    expect(find.text('Your watchlist is empty'), findsOneWidget);

    // Bottom navigation exposes both tabs.
    expect(find.text('Watchlist'), findsWidgets);
    expect(find.text('Portfolio'), findsOneWidget);
  });
}
