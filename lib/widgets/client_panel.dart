import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/client_status.dart';
import '../models/share_settings.dart';
import '../services/share_channel.dart';
import '../utils/messages.dart';
import 'credential_tile.dart';
import 'error_card.dart';
import 'numbered_step.dart';
import 'power_button.dart';
import 'stats_card.dart';

/// Client mode (Phone B): joins Phone A's Wi-Fi (optionally) and routes every
/// app through Phone A via a local VPN.
class ClientPanel extends StatefulWidget {
  const ClientPanel({super.key, required this.settings, this.onActiveChanged});

  /// Saved connection details (port, network name, password, auto-join).
  final ShareSettingsData settings;

  /// Lets the home screen lock the mode switch while connected.
  final ValueChanged<bool>? onActiveChanged;

  @override
  State<ClientPanel> createState() => _ClientPanelState();
}

class _ClientPanelState extends State<ClientPanel> {
  final _formKey = GlobalKey<FormState>();
  late final _port = TextEditingController(
    text: '${widget.settings.clientPort}',
  );
  late final _ssid = TextEditingController(text: widget.settings.clientSsid);
  late final _password = TextEditingController(
    text: widget.settings.clientPassphrase,
  );
  late bool _autoJoin = widget.settings.clientAutoJoin;
  bool _obscurePassword = true;

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
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_status.isActive) {
      await ShareChannel.disconnectClient();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      // Joining a Wi-Fi network needs the same nearby-devices/location
      // permission as sharing.
      if (_autoJoin) {
        final permissions = await ShareChannel.requestPermissions();
        if (!permissions.granted) {
          _showSnack(l.permissionRequired);
          return;
        }
      }
      if (!await ShareChannel.prepareVpn()) {
        _showSnack(l.errorVpnDenied);
        return;
      }
      await ShareChannel.connectClient(
        port: int.parse(_port.text),
        ssid: _ssid.text.trim(),
        passphrase: _password.text,
        autoJoin: _autoJoin,
      );
    } on PlatformException catch (e) {
      if (mounted) _showSnack(settingsErrorMessage(l, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Validators mirror ShareSettings.saveClient on the native side.

  String? _validatePort(String? value) {
    final port = int.tryParse(value ?? '');
    if (port == null || port < 1024 || port > 65535) {
      return AppLocalizations.of(context).errorInvalidPort;
    }
    return null;
  }

  String? _validateSsid(String? value) {
    final needsName = _autoJoin && !widget.settings.canPickNetwork;
    if (needsName && (value?.trim() ?? '').isEmpty) {
      return AppLocalizations.of(context).errorInvalidName;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (!_autoJoin) return null;
    final pass = value ?? '';
    final printableAscii = pass.codeUnits.every((c) => c >= 32 && c <= 126);
    if (pass.length < 8 || pass.length > 63 || !printableAscii) {
      return AppLocalizations.of(context).errorInvalidPassword;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (state, statusLabel) = switch (_status.kind) {
      ClientStatusKind.disconnected => (PowerState.idle, l.clientDisconnected),
      ClientStatusKind.connecting => (
        PowerState.working,
        _status.joining ? l.clientJoining : l.clientConnecting,
      ),
      ClientStatusKind.connected => (PowerState.active, l.clientConnected),
      ClientStatusKind.reconnecting => (
        PowerState.working,
        l.clientReconnecting(_status.reconnectAttempt),
      ),
      ClientStatusKind.error => (PowerState.error, l.statusError),
    };
    final connected = _status.kind == ClientStatusKind.connected;
    final reconnecting = _status.kind == ClientStatusKind.reconnecting;

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
        if (reconnecting) ...[
          _ReconnectingCard(errorCode: _status.errorCode),
          const SizedBox(height: 8),
          StatsCard(bytesUp: _status.bytesUp, bytesDown: _status.bytesDown),
        ] else if (connected) ...[
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
          _networkCard(context, l),
          const SizedBox(height: 16),
          _steps(context, l),
        ],
      ],
    );
  }

  /// Phone A's network name, password and port, plus the auto-join switch.
  Widget _networkCard(BuildContext context, AppLocalizations l) {
    final enabled = !_status.isActive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.clientNetworkTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.clientAutoJoin),
                subtitle: Text(l.clientAutoJoinHelp),
                value: _autoJoin,
                onChanged: enabled
                    ? (value) => setState(() => _autoJoin = value)
                    : null,
              ),
              if (_autoJoin) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ssid,
                  enabled: enabled,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l.networkName,
                    hintText: 'DIRECT-…',
                    helperText: widget.settings.canPickNetwork
                        ? l.clientSsidHintAny
                        : l.clientSsidHintExact,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateSsid,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: enabled,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l.password,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      tooltip: _obscurePassword
                          ? l.showPassword
                          : l.hidePassword,
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _port,
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l.proxyPort,
                  helperText: l.clientPortHelper,
                  border: const OutlineInputBorder(),
                ),
                validator: _validatePort,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _steps(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final steps = _autoJoin
        ? [l.clientAutoStep1, l.clientAutoStep2]
        : [l.clientStep1, l.clientStep2, l.clientStep3];
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
            if (!_autoJoin)
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

/// Shown while Phone A can't be reached and the app is retrying by itself.
class _ReconnectingCard extends StatelessWidget {
  const _ReconnectingCard({required this.errorCode});

  /// Why the last attempt failed, if any.
  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.sync_problem, color: scheme.onTertiaryContainer),
        title: Text(
          l.clientReconnectingHelp,
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        subtitle: errorCode == null
            ? null
            : Text(
                shareErrorMessage(l, errorCode),
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
      ),
    );
  }
}
