import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/share_settings.dart';
import '../models/share_status.dart';
import '../services/share_channel.dart';
import '../utils/constants.dart';
import '../widgets/connect_guide.dart';

/// "Connect a device" tab: how the other phone gets online (with or without the app).
class ConnectTab extends StatefulWidget {
  const ConnectTab({
    super.key,
    required this.settings,
    required this.onOpenReceive,
  });

  /// Saved settings, used for the guide's values while sharing is stopped.
  final ShareSettingsData settings;

  /// Opens Receive mode (for when this phone is the one that needs internet).
  final VoidCallback onOpenReceive;

  @override
  State<ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends State<ConnectTab> {
  ShareStatus _status = ShareStatus.stopped;
  StreamSubscription<ShareStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    // The stream only sends changes to late listeners, so read the current state too.
    ShareChannel.getStatus().then((status) {
      if (mounted) setState(() => _status = status);
    });
    _subscription = ShareChannel.statusStream.listen(
      (status) => setState(() => _status = status),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navConnect)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RecommendedCard(onOpenReceive: widget.onOpenReceive),
            const SizedBox(height: 8),
            _guide(),
          ],
        ),
      ),
    );
  }

  /// Uses the live values when running, otherwise the saved settings.
  Widget _guide() {
    final settings = widget.settings;
    final running = _status.kind == ShareStatusKind.running;
    final custom = settings.customNetworkSupported;
    final ssid = running ? _status.ssid : (custom ? settings.fullSsid : null);
    final password = running
        ? _status.passphrase
        : (custom ? settings.passphrase : null);
    return ConnectGuide(
      ssid: ssid ?? 'DIRECT-…',
      password: password ?? '…',
      host: running ? (_status.ownerIp ?? kDefaultOwnerIp) : kDefaultOwnerIp,
      port: '${running ? _status.port ?? kDefaultPort : settings.port}',
      initiallyExpanded: true,
      // Always offered; while sharing, only if its ports actually opened.
      whatsAppProxy: !running || _status.whatsAppProxy,
    );
  }
}

/// Installing the app on the other phone is the most complete option.
class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.onOpenReceive});

  final VoidCallback onOpenReceive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.receiveCardTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.receiveCardBody,
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onOpenReceive,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: Text(l.receiveButton),
            ),
          ],
        ),
      ),
    );
  }
}
