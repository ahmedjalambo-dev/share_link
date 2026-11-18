import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_link/l10n/app_localizations.dart';
import 'package:share_link/models/share_status.dart';
import 'package:share_link/theme.dart';
import 'package:share_link/widgets/devices_card.dart';

void main() {
  const devices = [
    ConnectedDevice(
      address: '192.168.49.137',
      name: 'Samsung Galaxy S24 Ultra of a very long name',
      bytesDown: 1023 * 1024 * 1024,
      bytesUp: 999 * 1024 * 1024,
      speedDown: 123 * 1024 * 1024,
      connections: 12,
    ),
    ConnectedDevice(address: '192.168.49.80', nickname: 'Ali', blocked: true),
    ConnectedDevice(address: '192.168.49.81'),
  ];

  Future<void> pump(
    WidgetTester tester,
    Locale locale,
    List<ConnectedDevice> list,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DevicesCard(devices: list),
          ),
        ),
      ),
    );
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('DevicesCard fits a 320 px screen ($locale)', (tester) async {
      await pump(tester, locale, devices);
      expect(tester.takeException(), isNull);
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('192.168.49.81'), findsOneWidget);
    });
  }

  testWidgets('DevicesCard menu offers Allow only for a blocked device', (
    tester,
  ) async {
    await pump(tester, const Locale('en'), devices);
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Disconnect'), findsNothing);
  });

  testWidgets('DevicesCard shows a hint when nobody is connected', (
    tester,
  ) async {
    await pump(tester, const Locale('en'), const []);
    expect(
      find.text('Devices appear here when they use the internet.'),
      findsOneWidget,
    );
  });
}
