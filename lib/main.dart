import 'package:flutter/material.dart';

import 'app_locale.dart';
import 'app_theme_mode.dart';
import 'l10n/app_localizations.dart';
import 'licenses.dart';
import 'screens/app_shell.dart';
import 'services/share_channel.dart';
import 'theme.dart';

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
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const AppShell(),
      ),
    );
  }
}
