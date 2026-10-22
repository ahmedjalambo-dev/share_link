import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/share_settings.dart';
import '../models/share_status.dart';
import '../services/share_channel.dart';
import '../widgets/client_panel.dart';
import '../widgets/connect_guide.dart';
import '../widgets/credential_tile.dart';
import '../widgets/error_card.dart';
import '../widgets/power_button.dart';
import '../widgets/stats_card.dart';
import '../widgets/wifi_qr_card.dart';
import 'settings_screen.dart';

enum AppMode { share, connect }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _defaultHost = '192.168.49.1';

  ShareStatus _status = ShareStatus.stopped;
  ShareSettingsData? _settings;
  AppMode _mode = AppMode.share;
  bool _clientActive = false;
  StreamSubscription<ShareStatus>? _subscription;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription = ShareChannel.statusStream.listen(
      (status) => setState(() => _status = status),
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ShareChannel.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _mode = settings.mode == 'connect' ? AppMode.connect : AppMode.share;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    _loadSettings();
  }

  void _setMode(AppMode mode) {
    setState(() => _mode = mode);
    ShareChannel.setMode(mode.name);
  }

  Future<void> _toggleSharing() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_status.isActive) {
        await ShareChannel.stop();
        return;
      }
      final permissions = await ShareChannel.requestPermissions();
      if (!permissions.granted) {
        _showPermissionDenied(permissions.permanentlyDenied);
        return;
      }
      await ShareChannel.start();
    } on PlatformException catch (e) {
      _showSnack(e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void _showPermissionDenied(bool permanently) {
    final l = AppLocalizations.of(context);
    _showSnack(
      l.permissionRequired,
      action: permanently
          ? SnackBarAction(
              label: l.settingsAction,
              onPressed: () => ShareChannel.openSystemSettings('app'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = _settings;
    // Don't let the user switch modes while either side is running.
    final modeLocked = _status.isActive || _clientActive;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l.settingsTitle,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<AppMode>(
              segments: [
                ButtonSegment(
                  value: AppMode.share,
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(l.modeShare),
                ),
                ButtonSegment(
                  value: AppMode.connect,
                  icon: const Icon(Icons.vpn_lock),
                  label: Text(l.modeConnect),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: modeLocked
                  ? null
                  : (selection) => _setMode(selection.first),
            ),
            const SizedBox(height: 24),
            if (settings == null)
              const Center(child: CircularProgressIndicator())
            else if (_mode == AppMode.connect)
              ClientPanel(
                initialPort: settings.clientPort,
                onActiveChanged: (active) {
                  if (active != _clientActive) {
                    setState(() => _clientActive = active);
                  }
                },
              )
            else
              ..._shareView(l),
          ],
        ),
      ),
    );
  }

  List<Widget> _shareView(AppLocalizations l) {
    final running = _status.kind == ShareStatusKind.running;
    final (state, statusLabel) = switch (_status.kind) {
      ShareStatusKind.stopped => (PowerState.idle, l.statusStopped),
      ShareStatusKind.starting => (PowerState.working, l.statusStarting),
      ShareStatusKind.running => (PowerState.active, l.statusRunning),
      ShareStatusKind.error => (PowerState.error, l.statusError),
    };
    return [
      Center(
        child: PowerButton(
          state: state,
          label: _status.isActive ? l.stop : l.start,
          busy: _busy,
          onPressed: _toggleSharing,
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: StatusChip(state: state, label: statusLabel),
      ),
      const SizedBox(height: 24),
      if (_status.kind == ShareStatusKind.error)
        ErrorCard(code: _status.errorCode, detail: _status.errorDetail),
      if (running) ...[
        if (!_status.upstreamAvailable) const _WifiLostCard(),
        _credentials(l),
        const SizedBox(height: 8),
        WifiQrCard(
          ssid: _status.ssid ?? '',
          password: _status.passphrase ?? '',
        ),
        const SizedBox(height: 8),
        StatsCard(
          connections: _status.activeConnections,
          bytesUp: _status.bytesUp,
          bytesDown: _status.bytesDown,
        ),
      ],
      if (_status.kind == ShareStatusKind.stopped)
        Text(
          l.hintStopped,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      const SizedBox(height: 8),
      _guide(running),
    ];
  }

  Widget _credentials(AppLocalizations l) {
    return Card(
      child: Column(
        children: [
          CredentialTile(
            icon: Icons.wifi,
            label: l.networkName,
            value: _status.ssid ?? '',
          ),
          CredentialTile(
            icon: Icons.key,
            label: l.password,
            value: _status.passphrase ?? '',
          ),
          CredentialTile(
            icon: Icons.dns,
            label: l.proxyIp,
            value: _status.ownerIp ?? '',
          ),
          CredentialTile(
            icon: Icons.numbers,
            label: l.proxyPort,
            value: '${_status.port ?? ''}',
          ),
        ],
      ),
    );
  }

  /// Uses the live values when running, otherwise the saved settings.
  Widget _guide(bool running) {
    final settings = _settings;
    final custom = settings?.customNetworkSupported ?? false;
    final ssid = running ? _status.ssid : (custom ? settings?.fullSsid : null);
    final password = running
        ? _status.passphrase
        : (custom ? settings?.passphrase : null);
    return ConnectGuide(
      // Re-create when sharing starts/stops so initiallyExpanded applies.
      key: ValueKey(running),
      ssid: ssid ?? 'DIRECT-…',
      password: password ?? '…',
      host: running ? (_status.ownerIp ?? _defaultHost) : _defaultHost,
      port: '${running ? _status.port : settings?.port ?? 8282}',
      initiallyExpanded: running,
    );
  }
}

class _WifiLostCard extends StatelessWidget {
  const _WifiLostCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.wifi_off, color: scheme.onTertiaryContainer),
        title: Text(
          AppLocalizations.of(context).wifiLost,
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
      ),
    );
  }
}
