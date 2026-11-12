import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../app_theme_mode.dart';
import '../l10n/app_localizations.dart';
import '../models/share_settings.dart';
import '../services/share_channel.dart';
import '../utils/messages.dart';
import '../widgets/settings_dialogs.dart';

/// Settings tab: grouped lists like the phone's own settings; each value opens a dialog.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  ShareSettingsData? _settings;
  bool? _batteryUnrestricted;
  String _version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system battery dialog.
    if (state == AppLifecycleState.resumed) _refreshBattery();
  }

  Future<void> _load() async {
    final settings = await ShareChannel.getSettings();
    final info = await ShareChannel.getAppInfo();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _version = '${info.version} (${info.build})';
    });
    await _refreshBattery();
  }

  Future<void> _refreshBattery() async {
    final unrestricted = await ShareChannel.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _batteryUnrestricted = unrestricted);
  }

  /// Saves one changed value together with the current others.
  Future<void> _save({String? name, String? password, int? port}) async {
    final l = AppLocalizations.of(context);
    final current = _settings!;
    try {
      final saved = await ShareChannel.saveSettings(
        networkName: name ?? current.networkName,
        passphrase: password ?? current.passphrase,
        port: port ?? current.port,
      );
      final running = (await ShareChannel.getStatus()).isActive;
      if (!mounted) return;
      setState(() => _settings = saved);
      _showSnack(
        running ? l.restartToApply : l.saved,
        action: running
            ? SnackBarAction(label: l.restart, onPressed: ShareChannel.restart)
            : null,
      );
    } on PlatformException catch (e) {
      if (mounted) _showSnack(settingsErrorMessage(l, e.code));
    }
  }

  Future<void> _editName() async {
    final l = AppLocalizations.of(context);
    final settings = _settings!;
    final value = await showTextSettingDialog(
      context,
      title: l.networkName,
      initialValue: settings.networkName,
      maxLength: 22,
      helper: (value) =>
          l.networkNameHelper(settings.ssidPrefix + value.trim()),
      validator: _validateName,
    );
    if (value != null) await _save(name: value.trim());
  }

  Future<void> _editPassword() async {
    final l = AppLocalizations.of(context);
    final value = await showTextSettingDialog(
      context,
      title: l.password,
      initialValue: _settings!.passphrase,
      helper: (_) => l.passwordHelper,
      password: true,
      validator: _validatePassword,
    );
    if (value != null) await _save(password: value);
  }

  Future<void> _editPort() async {
    final l = AppLocalizations.of(context);
    final value = await showTextSettingDialog(
      context,
      title: l.proxyPort,
      initialValue: '${_settings!.port}',
      helper: (_) => l.portHelper,
      numeric: true,
      validator: _validatePort,
    );
    if (value != null) await _save(port: int.parse(value));
  }

  Future<void> _pickLanguage() async {
    final l = AppLocalizations.of(context);
    final code = await showChoiceDialog(
      context,
      title: l.sectionLanguage,
      options: _languages(l),
      selected: _settings!.language,
    );
    if (code == null) return;
    AppLocale.notifier.value = AppLocale.fromCode(code);
    await ShareChannel.setLanguage(code);
    await _reload();
  }

  Future<void> _pickTheme() async {
    final l = AppLocalizations.of(context);
    final code = await showChoiceDialog(
      context,
      title: l.themeTitle,
      options: _themes(l),
      selected: _settings!.themeMode,
    );
    if (code == null) return;
    AppThemeMode.notifier.value = AppThemeMode.fromCode(code);
    await ShareChannel.setThemeMode(code);
    await _reload();
  }

  Future<void> _reload() async {
    final settings = await ShareChannel.getSettings();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _addTile() async {
    final l = AppLocalizations.of(context);
    final result = await ShareChannel.requestAddTile();
    if (!mounted) return;
    final message = switch (result) {
      'added' => l.tileAdded,
      'alreadyAdded' => l.tileAlreadyAdded,
      'notAdded' => l.tileNotAdded,
      _ => l.tileAddHint,
    };
    _showSnack(message);
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  static Map<String, String> _languages(AppLocalizations l) => {
    'system': l.languageSystem,
    'en': l.languageEnglish,
    'ar': l.languageArabic,
  };

  static Map<String, String> _themes(AppLocalizations l) => {
    'system': l.themeSystem,
    'light': l.themeLight,
    'dark': l.themeDark,
  };

  // Validators mirror ShareSettings.save on the native side.

  String? _validateName(String? value) {
    final l = AppLocalizations.of(context);
    final name = value?.trim() ?? '';
    if (name.isEmpty) return l.errorInvalidName;
    if (utf8.encode(_settings!.ssidPrefix + name).length > 32) {
      return l.errorNameTooLong;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final pass = value ?? '';
    final printableAscii = pass.codeUnits.every((c) => c >= 32 && c <= 126);
    if (pass.length < 8 || pass.length > 63 || !printableAscii) {
      return AppLocalizations.of(context).errorInvalidPassword;
    }
    return null;
  }

  String? _validatePort(String? value) {
    final port = int.tryParse(value ?? '');
    if (port == null || port < 1024 || port > 65535) {
      return AppLocalizations.of(context).errorInvalidPort;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _SectionHeader(l.sectionNetwork),
                if (!settings.customNetworkSupported)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    subtitle: Text(l.customNetworkUnsupported),
                  ),
                _ValueTile(
                  icon: Icons.wifi,
                  title: l.networkName,
                  value: settings.fullSsid,
                  onTap: settings.customNetworkSupported ? _editName : null,
                ),
                _ValueTile(
                  icon: Icons.key,
                  title: l.password,
                  value: settings.passphrase,
                  onTap: settings.customNetworkSupported ? _editPassword : null,
                ),
                _ValueTile(
                  icon: Icons.numbers,
                  title: l.proxyPort,
                  value: '${settings.port}',
                  onTap: _editPort,
                ),
                _SectionHeader(l.sectionAppearance),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.sectionLanguage),
                  subtitle: Text(_languages(l)[settings.language] ?? ''),
                  onTap: _pickLanguage,
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text(l.themeTitle),
                  subtitle: Text(_themes(l)[settings.themeMode] ?? ''),
                  onTap: _pickTheme,
                ),
                _SectionHeader(l.sectionDevice),
                _BatteryTile(
                  unrestricted: _batteryUnrestricted,
                  onAllow: ShareChannel.requestIgnoreBatteryOptimizations,
                ),
                // Android 13+ can add the tile with one prompt; older
                // versions need the Quick Settings editor.
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: Text(l.sectionTile),
                  subtitle: Text(
                    settings.apiLevel >= 33 ? l.tileAddButton : l.tileAddHint,
                  ),
                  onTap: settings.apiLevel >= 33 ? _addTile : null,
                ),
                _SectionHeader(l.sectionAbout),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.version),
                  subtitle: Text(_version, textDirection: TextDirection.ltr),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l.licenses),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l.appTitle,
                    applicationVersion: _version,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A setting with its current value underneath (always LTR); disabled when [onTap] is null.
class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value, textDirection: TextDirection.ltr),
      trailing: onTap == null ? null : const Icon(Icons.edit_outlined),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

class _BatteryTile extends StatelessWidget {
  const _BatteryTile({required this.unrestricted, required this.onAllow});

  final bool? unrestricted;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (unrestricted == null) {
      return const ListTile(leading: Icon(Icons.battery_unknown));
    }
    final ok = unrestricted!;
    return ListTile(
      leading: Icon(
        ok ? Icons.battery_full : Icons.battery_alert,
        color: ok ? scheme.primary : scheme.error,
      ),
      title: Text(ok ? l.batteryUnrestricted : l.batteryRestricted),
      subtitle: Text(ok ? l.batteryUnrestrictedBody : l.batteryRestrictedBody),
      trailing: ok
          ? null
          : FilledButton.tonal(onPressed: onAllow, child: Text(l.batteryAllow)),
    );
  }
}
