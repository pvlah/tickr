import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';
import 'src/data/persistence/local_store.dart';

Future<void> main() async {
  // Required before any async work prior to runApp (plugin channels, Hive).
  WidgetsFlutterBinding.ensureInitialized();

  // Open a single Hive box for local persistence (works on web via IndexedDB
  // and on mobile via files — no platform code needed).
  await Hive.initFlutter();
  final box = await Hive.openBox<String>('tickr');

  runApp(
    ProviderScope(
      // Swap the no-op default store for the real Hive-backed one. Everything
      // below (portfolio + watchlist Notifiers) now persists automatically.
      overrides: [localStoreProvider.overrideWithValue(HiveStore(box))],
      child: const TickrApp(),
    ),
  );
}
