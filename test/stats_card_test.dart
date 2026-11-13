import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_link/l10n/app_localizations.dart';
import 'package:share_link/theme.dart';
import 'package:share_link/widgets/stats_card.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('StatsCard fits a 320 px screen with large values ($locale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatsCard(
                connections: 128,
                bytesUp: 999 * 1024 * 1024,
                bytesDown: 1023 * 1024 * 1024,
                speedUp: 999 * 1024,
                speedDown: 123 * 1024 * 1024,
                startedAt: DateTime.now().subtract(
                  const Duration(hours: 12, minutes: 34, seconds: 56),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
