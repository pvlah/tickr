import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remote Config keys + the A/B test it drives (wired into the UI on Day 6).
abstract final class RemoteConfigKeys {
  /// Controls the watchlist layout A/B test: 'list' (default rows) vs 'cards'.
  static const watchlistLayout = 'watchlist_layout';
}

/// Watchlist layout variants for the A/B test.
enum WatchlistLayout {
  list,
  cards;

  static WatchlistLayout fromString(String v) =>
      v == 'cards' ? WatchlistLayout.cards : WatchlistLayout.list;
}

/// The FirebaseRemoteConfig instance, set up in `main()` (fetch + defaults) and
/// exposed here. Overridable in tests.
final remoteConfigProvider = Provider<FirebaseRemoteConfig>(
  (ref) => throw UnimplementedError('Initialize in main() and override'),
);

/// The watchlist layout variant Remote Config currently dictates. A plain
/// Provider that reads the already-fetched config value — the UI watches this
/// to pick a layout.
final watchlistLayoutProvider = Provider<WatchlistLayout>((ref) {
  final config = ref.watch(remoteConfigProvider);
  return WatchlistLayout.fromString(
    config.getString(RemoteConfigKeys.watchlistLayout),
  );
});

/// Initializes Remote Config: sets defaults (so the app works offline / before
/// the first fetch) and pulls the latest values. Called once from `main()`.
Future<FirebaseRemoteConfig> initRemoteConfig() async {
  final rc = FirebaseRemoteConfig.instance;
  await rc.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );
  await rc.setDefaults(const {RemoteConfigKeys.watchlistLayout: 'list'});
  try {
    await rc.fetchAndActivate();
  } catch (_) {
    // Network/quota hiccup → fall back to defaults. Never block app startup.
  }
  return rc;
}
