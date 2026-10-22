import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../l10n/app_localizations.dart';
import '../models/share_settings.dart';
import '../services/share_channel.dart';
import '../utils/constants.dart';
import '../utils/messages.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _port = TextEditingController();

  ShareSettingsData? _settings;
  String _language = 'system';
  bool? _batteryUnrestricted;
  bool _obscurePassword = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _name.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    _password.dispose();
    _port.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system battery dialog.
    if (state == AppLifecycleState.resumed) _refreshBattery();
  }

  Future<void> _load() async {
    final settings = await ShareChannel.getSettings();
    if (!mounted) return;
    _name.text = settings.networkName;
    _password.text = settings.passphrase;
    _port.text = '${settings.port}';
    setState(() {
      _settings = settings;
      _language = settings.language;
    });
    await _refreshBattery();
  }

  Future<void> _refreshBattery() async {
    final unrestricted = await ShareChannel.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _batteryUnrestricted = unrestricted);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await ShareChannel.saveSettings(
        networkName: _name.text.trim(),
        passphrase: _password.text,
        port: int.parse(_port.text),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setLanguage(String code) async {
    setState(() => _language = code);
    AppLocale.notifier.value = AppLocale.fromCode(code);
    await ShareChannel.setLanguage(code);
  }

  void _generatePassword() {
    final random = Random.secure();
    setState(() {
      _password.text = List.generate(
        10,
        (_) => kPasswordChars[random.nextInt(kPasswordChars.length)],
      ).join();
      _obscurePassword = false;
    });
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

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
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader(l.sectionNetwork),
                  if (!settings.customNetworkSupported)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l.customNetworkUnsupported),
                    ),
                  TextFormField(
                    controller: _name,
                    enabled: settings.customNetworkSupported,
                    textDirection: TextDirection.ltr,
                    maxLength: 22,
                    decoration: InputDecoration(
                      labelText: l.networkName,
                      helperText: l.networkNameHelper(
                        settings.ssidPrefix + _name.text.trim(),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: settings.customNetworkSupported
                        ? _validateName
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    enabled: settings.customNetworkSupported,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: l.password,
                      helperText: l.passwordHelper,
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            tooltip: _obscurePassword
                                ? l.showPassword
                                : l.hidePassword,
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.autorenew),
                            tooltip: l.generatePassword,
                            onPressed: settings.customNetworkSupported
                                ? _generatePassword
                                : null,
                          ),
                        ],
                      ),
                    ),
                    validator: settings.customNetworkSupported
                        ? _validatePassword
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _port,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: l.proxyPort,
                      helperText: l.portHelper,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validatePort,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(l.save),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(l.sectionLanguage),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'system',
                        label: Text(l.languageSystem),
                      ),
                      ButtonSegment(
                        value: 'en',
                        label: Text(l.languageEnglish),
                      ),
                      ButtonSegment(value: 'ar', label: Text(l.languageArabic)),
                    ],
                    selected: {_language},
                    onSelectionChanged: (selection) =>
                        _setLanguage(selection.first),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(l.sectionBattery),
                  _BatteryTile(
                    unrestricted: _batteryUnrestricted,
                    onAllow: ShareChannel.requestIgnoreBatteryOptimizations,
                  ),
                ],
              ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
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
    if (unrestricted == null) return const LinearProgressIndicator();
    final ok = unrestricted!;
    return Card(
      child: ListTile(
        leading: Icon(
          ok ? Icons.battery_full : Icons.battery_alert,
          color: ok
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(ok ? l.batteryUnrestricted : l.batteryRestricted),
        subtitle: Text(
          ok ? l.batteryUnrestrictedBody : l.batteryRestrictedBody,
        ),
        trailing: ok
            ? null
            : FilledButton.tonal(
                onPressed: onAllow,
                child: Text(l.batteryAllow),
              ),
      ),
    );
  }
}
