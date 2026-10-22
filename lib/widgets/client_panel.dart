import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/client_status.dart';
import '../services/share_channel.dart';
import 'credential_tile.dart';
import 'error_card.dart';
import 'numbered_step.dart';
import 'power_button.dart';
import 'stats_card.dart';

/// Client mode (Phone B): routes every app through Phone A via a local VPN.
class ClientPanel extends StatefulWidget {
  const ClientPanel({
    super.key,
    required this.initialPort,
    this.onActiveChanged,
  });

  final int initialPort;

  /// Lets the home screen lock the mode switch while connected.
  final ValueChanged<bool>? onActiveChanged;

  @override
  State<ClientPanel> createState() => _ClientPanelState();
}

class _ClientPanelState extends State<ClientPanel> {
  late final _port = TextEditingController(text: '${widget.initialPort}');
  ClientStatus _status = ClientStatus.disconnected;
  StreamSubscription<ClientStatus>? _subscription;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription = ShareChannel.clientStatusStream.listen((status) {
      setState(() => _status = status);
      widget.onActiveChanged?.call(status.isActive);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _port.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (_status.isActive) {
        await ShareChannel.disconnectClient();
        return;
      }
      final port = int.tryParse(_port.text);
      if (port == null || port < 1024 || port > 65535) {
        _showSnack(l.errorInvalidPort);
        return;
      }
      if (!await ShareChannel.prepareVpn()) {
        _showSnack(l.errorVpnDenied);
        return;
      }
      await ShareChannel.connectClient(port);
    } on PlatformException catch (e) {
      _showSnack(e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (state, statusLabel) = switch (_status.kind) {
      ClientStatusKind.disconnected => (PowerState.idle, l.clientDisconnected),
      ClientStatusKind.connecting => (PowerState.working, l.clientConnecting),
      ClientStatusKind.connected => (PowerState.active, l.clientConnected),
      ClientStatusKind.error => (PowerState.error, l.statusError),
    };
    final connected = _status.kind == ClientStatusKind.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: PowerButton(
            state: state,
            label: _status.isActive ? l.disconnect : l.connect,
            busy: _busy,
            onPressed: _toggle,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: StatusChip(state: state, label: statusLabel),
        ),
        const SizedBox(height: 24),
        if (_status.kind == ClientStatusKind.error)
          ErrorCard(code: _status.errorCode, detail: _status.errorDetail),
        if (connected) ...[
          Card(
            child: CredentialTile(
              icon: Icons.phone_android,
              label: l.clientPhoneA,
              value: '${_status.host}:${_status.port}',
            ),
          ),
          const SizedBox(height: 8),
          StatsCard(bytesUp: _status.bytesUp, bytesDown: _status.bytesDown),
        ] else ...[
          TextField(
            controller: _port,
            enabled: !_status.isActive,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: l.proxyPort,
              helperText: l.clientPortHelper,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _steps(context, l),
        ],
      ],
    );
  }

  Widget _steps(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final steps = [l.clientStep1, l.clientStep2, l.clientStep3];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.clientStepsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              NumberedStep(number: i + 1, text: steps[i]),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => ShareChannel.openSystemSettings('wifi'),
                icon: const Icon(Icons.wifi),
                label: Text(l.openWifiSettings),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.clientBankNote,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
