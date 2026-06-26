import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/portfolio/portfolio_screen.dart';
import '../../presentation/watchlist/watchlist_screen.dart';
import '../widgets/home_shell.dart';

/// Centralized route names — referenced instead of raw path strings so renames
/// are a one-line change and typos become compile errors.
abstract final class Routes {
  static const watchlist = '/watchlist';
  static const portfolio = '/portfolio';
}

// Separate navigator keys: one root, one per shell branch. go_router needs
// these to keep each tab's navigation stack independent.
final _rootKey = GlobalKey<NavigatorState>();
final _watchlistKey = GlobalKey<NavigatorState>();
final _portfolioKey = GlobalKey<NavigatorState>();

/// The app's single [GoRouter]. A [StatefulShellRoute.indexedStack] keeps all
/// branches alive (IndexedStack) so tab state persists across switches.
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: Routes.watchlist,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _watchlistKey,
          routes: [
            GoRoute(
              path: Routes.watchlist,
              builder: (context, state) => const WatchlistScreen(),
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
