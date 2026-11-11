import 'package:flutter/material.dart';

import 'app_locale.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/share_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final settings = await ShareChannel.getSettings();
    AppLocale.notifier.value = AppLocale.fromCode(settings.language);
  } catch (_) {
    // Fall back to the system language.
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
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        home: const HomeScreen(),
      ),
    );
  }
}
