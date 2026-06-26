import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget. A [ConsumerWidget] is the Riverpod-aware version of
/// [StatelessWidget]: its [build] gets a [WidgetRef] so it can `ref.watch`
/// providers. We don't watch anything yet, but using it here means theme-mode
/// (light/dark toggle) can later be driven by a provider with no refactor.
class TickrApp extends ConsumerWidget {
  const TickrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Tickr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follow the OS setting for now. A settings toggle can override this
      // later by swapping this for a watched provider value.
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
