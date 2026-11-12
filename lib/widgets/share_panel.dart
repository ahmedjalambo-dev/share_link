import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/share_status.dart';
import '../services/share_channel.dart';
import 'error_card.dart';
import 'network_card.dart';
import 'power_button.dart';
import 'qr_sheet.dart';
import 'stats_card.dart';
import 'status_banner.dart';

/// Share mode (Phone A): the power button, then the network and live stats while running.
/// The QR opens in a bottom sheet and the full guide lives in the Connect a device tab.
class SharePanel extends StatefulWidget {
  const SharePanel({
    super.key,
    required this.onShowGuide,
    this.receiving = false,
  });

  /// Switches to the Connect a device tab.
  final VoidCallback onShowGuide;

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
    final (state, statusLabel) = switch (_status.kind) {
      ShareStatusKind.stopped => (PowerState.idle, l.statusStopped),
      ShareStatusKind.starting => (PowerState.working, l.statusStarting),
      ShareStatusKind.running => (PowerState.active, l.statusRunning),
      ShareStatusKind.error => (PowerState.error, l.statusError),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Center(
          child: StatusChip(state: state, label: statusLabel),
        ),
        const SizedBox(height: 20),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_status.kind),
              child: _details(context, l),
            ),
          ),
        ),
      ],
    );
  }

  /// What sits under the button for the current state.
  Widget _details(BuildContext context, AppLocalizations l) {
    switch (_status.kind) {
      case ShareStatusKind.running:
        final ssid = _status.ssid ?? '';
        final password = _status.passphrase ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_status.upstreamAvailable) ...[
              const _WifiLostBanner(),
              const SizedBox(height: 12),
            ],
            NetworkCard(
              ssid: ssid,
              password: password,
              onShowQr: () =>
                  showQrSheet(context, ssid: ssid, password: password),
              onShowGuide: widget.onShowGuide,
            ),
            const SizedBox(height: 12),
            StatsCard(
              connections: _status.activeConnections,
              bytesUp: _status.bytesUp,
              bytesDown: _status.bytesDown,
            ),
          ],
        );
      case ShareStatusKind.error:
        return ErrorCard(code: _status.errorCode, detail: _status.errorDetail);
      case ShareStatusKind.stopped:
        return Text(
          l.hintStopped,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      case ShareStatusKind.starting:
        return const SizedBox.shrink();
    }
  }
}

class _WifiLostBanner extends StatelessWidget {
  const _WifiLostBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return StatusBanner(
      icon: Icons.wifi_off,
      message: l.wifiLost,
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
      actionLabel: l.openWifiSettings,
      onAction: () => ShareChannel.openSystemSettings('wifi'),
    );
  }
}
