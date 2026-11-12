import 'package:flutter/material.dart';

/// IBM Plex Sans has no Arabic letters, so Arabic text (whole Arabic UI or
/// mixed strings) is drawn with the matching IBM Plex Sans Arabic.
const _latinFont = 'IBMPlexSans';
const _arabicFallback = ['IBMPlexSansArabic'];

/// The app's teal Material 3 theme, shared by light and dark mode.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: brightness,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: _latinFont,
    fontFamilyFallback: _arabicFallback,
    // Flat tonal cards instead of shadows; colored cards keep their own color.
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: rounded,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: _latinFont,
        fontFamilyFallback: _arabicFallback,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
  );
}
