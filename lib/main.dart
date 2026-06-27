import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/remote_config/remote_config.dart';
import 'src/data/persistence/local_store.dart';
import 'src/demo/demo_mode.dart';

Future<void> main() async {
  // Required before any async work prior to runApp (plugin channels, Hive).
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase first (auth/analytics/remote config all depend on it).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final remoteConfig = await initRemoteConfig();

  // Local persistence (web: IndexedDB, mobile: files).
  await Hive.initFlutter();
  final box = await Hive.openBox<String>('tickr');

  runApp(
    ProviderScope(
      overrides: [
        // Swap the no-op default store for the real Hive-backed one.
        localStoreProvider.overrideWithValue(HiveStore(box)),
        // Provide the initialized Remote Config (fetched + defaults applied).
        remoteConfigProvider.overrideWithValue(remoteConfig),
        // Public demo build only: skip sign-in + seed a portfolio.
        if (kDemoMode) ...demoOverrides,
      ],
      child: const TickrApp(),
    ),
  );
}
