import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/sign_in_screen.dart';
import '../../presentation/detail/coin_detail_screen.dart';
import '../../presentation/portfolio/portfolio_screen.dart';
import '../../presentation/watchlist/watchlist_screen.dart';
import '../analytics/analytics.dart';
import '../auth/auth_providers.dart';
import '../widgets/home_shell.dart';

/// Centralized route names — referenced instead of raw path strings so renames
/// are a one-line change and typos become compile errors.
abstract final class Routes {
  static const signIn = '/signin';
  static const watchlist = '/watchlist';
  static const portfolio = '/portfolio';

  /// Detail lives UNDER the watchlist branch, so opening a coin keeps the
  /// bottom nav visible and "back" returns to the list.
  static String coinDetail(String id) => '/watchlist/coin/$id';
}

// Separate navigator keys: one root, one per shell branch. go_router needs
// these to keep each tab's navigation stack independent.
final _rootKey = GlobalKey<NavigatorState>();
final _watchlistKey = GlobalKey<NavigatorState>();
final _portfolioKey = GlobalKey<NavigatorState>();

/// The app's [GoRouter], as a provider so it can read auth + analytics through
/// test-friendly seams ([isAuthenticatedProvider], [navigatorObserversProvider])
/// rather than touching Firebase singletons directly.
///
/// A [_AuthRefresh] listenable re-runs [redirect] whenever auth state changes;
/// the redirect reads the latest auth value and gates the app behind sign-in.
final routerProvider = Provider<GoRouter>((ref) {
  final observers = ref.watch(navigatorObserversProvider);

  final refresh = _AuthRefresh();
  // Re-evaluate the redirect whenever sign-in status changes.
  ref.listen(isAuthenticatedProvider, (_, _) => refresh.bump());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.watchlist,
    refreshListenable: refresh,
    observers: observers,
    redirect: (context, state) {
      final auth = ref.read(isAuthenticatedProvider);
      // Don't redirect while the first auth state is still resolving.
      if (auth.isLoading) return null;
      final loggedIn = auth.asData?.value ?? false;
      final atSignIn = state.matchedLocation == Routes.signIn;
      if (!loggedIn) return atSignIn ? null : Routes.signIn;
      if (atSignIn) return Routes.watchlist;
      return null; // no redirect
    },
    routes: [
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _watchlistKey,
            routes: [
              GoRoute(
                path: Routes.watchlist,
                builder: (context, state) => const WatchlistScreen(),
                routes: [
                  GoRoute(
                    // Relative path → resolves to /watchlist/coin/:id
                    path: 'coin/:id',
                    builder: (context, state) =>
                        CoinDetailScreen(coinId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _portfolioKey,
            routes: [
              GoRoute(
                path: Routes.portfolio,
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// A tiny [Listenable] GoRouter can subscribe to. We `bump()` it from a Riverpod
/// `ref.listen` on auth state, which makes GoRouter re-run its redirect.
class _AuthRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}
