// Smoke test: the app boots, renders the watchlist tab, and shows the
// bottom navigation. Real feature tests arrive alongside their features.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/src/app.dart';
import 'package:tickr/src/domain/entities/coin.dart';
import 'package:tickr/src/presentation/markets/live_prices.dart';

void main() {
  testWidgets('app boots into the Watchlist tab with bottom nav',
      (WidgetTester tester) async {
    // Override the shared price stream with empty data so the smoke test is
    // hermetic — no real HTTP. Both the watchlist and portfolio derive from it.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          livePricesProvider
              .overrideWith((ref) => Stream.value(<String, Coin>{})),
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
