import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/share_status.dart';
import '../services/share_channel.dart';
import 'credential_tile.dart';
import 'error_card.dart';
import 'power_button.dart';
import 'stats_card.dart';
import 'wifi_qr_card.dart';

/// Share mode (Phone A): Wi-Fi Direct group + proxy, with credentials, QR and stats.
class SharePanel extends StatefulWidget {
  const SharePanel({super.key, this.receiving = false});

  /// Receive mode is active on this phone; sharing can't start until it's disconnected.
  final bool receiving;

  @override
  State<SharePanel> createState() => _SharePanelState();
}

class _SharePanelState extends State<SharePanel> {
  ShareStatus _status = ShareStatus.stopped;
  StreamSubscription<ShareStatus>? _subscription;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription = ShareChannel.statusStream.listen((status) {
      setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_status.isActive) {
        await ShareChannel.stop();
        return;
      }
      if (widget.receiving) {
        _showSnack(AppLocalizations.of(context).stopReceivingFirst);
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
    final running = _status.kind == ShareStatusKind.running;
    final (state, statusLabel) = switch (_status.kind) {
      ShareStatusKind.stopped => (PowerState.idle, l.statusStopped),
      ShareStatusKind.starting => (PowerState.working, l.statusStarting),
      ShareStatusKind.running => (PowerState.active, l.statusRunning),
      ShareStatusKind.error => (PowerState.error, l.statusError),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: PowerButton(
            state: state,
            label: _status.isActive ? l.stop : l.start,
            busy: _busy,
            onPressed: _toggle,
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
      ],
    );
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
