@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/src/core/theme/app_theme.dart';
import 'package:tickr/src/core/widgets/change_badge.dart';

/// Golden (pixel-snapshot) test for the [ChangeBadge] in both gain and loss
/// states. Tagged `golden` so CI (which runs on a different OS) can exclude it
/// via `--exclude-tags golden` — golden images are platform-sensitive, so we
/// verify them locally and run `flutter test --update-goldens` to refresh.
void main() {
  testWidgets('ChangeBadge renders gain (green) and loss (red) variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: Padding(
              key: Key('badges'),
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChangeBadge(changePercent: 4.21),
                  SizedBox(width: 16),
                  ChangeBadge(changePercent: -2.75),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const Key('badges')),
      matchesGoldenFile('goldens/change_badge.png'),
    );
  });
}
