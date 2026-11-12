import 'package:flutter/material.dart';

/// App-wide light/dark choice, stored natively like the language.
class AppThemeMode {
  static final notifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  static ThemeMode fromCode(String code) => switch (code) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
