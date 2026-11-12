import 'package:flutter/material.dart';

import 'app_locale.dart';
import 'app_theme_mode.dart';
import 'l10n/app_localizations.dart';
import 'licenses.dart';
import 'screens/app_shell.dart';
import 'services/share_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerLicenses();
  try {
    final settings = await ShareChannel.getSettings();
    AppLocale.notifier.value = AppLocale.fromCode(settings.language);
    AppThemeMode.notifier.value = AppThemeMode.fromCode(settings.themeMode);
  } catch (_) {
    // Fall back to the system language and theme.
  }
  runApp(const ShareLinkApp());
}

class ShareLinkApp extends StatelessWidget {
  const ShareLinkApp({super.key});

  /// IBM Plex Sans has no Arabic letters, so Arabic text (whole Arabic UI or
  /// mixed strings) is drawn with the matching IBM Plex Sans Arabic.
  static const _latinFont = 'IBMPlexSans';
  static const _arabicFallback = ['IBMPlexSansArabic'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLocale.notifier, AppThemeMode.notifier]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: AppLocale.notifier.value,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: AppThemeMode.notifier.value,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          fontFamily: _latinFont,
          fontFamilyFallback: _arabicFallback,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          fontFamily: _latinFont,
          fontFamilyFallback: _arabicFallback,
        ),
        home: const AppShell(),
      ),
    );
  }
}
