import 'package:flutter/widgets.dart';

/// App-wide language choice. `null` follows the system language.
class AppLocale {
  static final notifier = ValueNotifier<Locale?>(null);

  static Locale? fromCode(String code) => switch (code) {
    'en' => const Locale('en'),
    'ar' => const Locale('ar'),
    _ => null,
  };
}
