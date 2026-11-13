import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/share_settings.dart';
import '../models/share_status.dart';
import '../services/share_channel.dart';
import '../utils/constants.dart';
import '../widgets/copy_chip.dart';
import '../widgets/method_card.dart';
import '../widgets/numbered_step.dart';
import '../widgets/wifi_qr_view.dart';

/// Ports of Phone A's always-on WhatsApp relay (see WhatsAppRelay.kt).
const _whatsAppChatPort = '5222';
const _whatsAppMediaPort = '7777';

/// Extra DNS server suggested for apps that check the internet themselves.
const _publicDns = '1.1.1.1';

enum _Method { proxy, telegram, whatsApp, dns }

/// "Connect a device" tab: the QR, the recommended way (the app on both phones)
/// and the ways that need nothing installed on the other phone.
class ConnectTab extends StatefulWidget {
  const ConnectTab({
    super.key,
    required this.settings,
    required this.onOpenReceive,
    required this.onGoHome,
  });

  /// Saved settings, used for the values shown while sharing is stopped.
  final ShareSettingsData settings;

  /// Opens Receive mode (for when this phone is the one that needs internet).
  final VoidCallback onOpenReceive;

  /// Switches to the Home tab, where sharing starts.
  final VoidCallback onGoHome;

  @override
  State<ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends State<ConnectTab> {
  ShareStatus _status = ShareStatus.stopped;
  StreamSubscription<ShareStatus>? _subscription;
  _Method? _open = _Method.proxy;

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

  void _toggle(_Method method) =>
      setState(() => _open = _open == method ? null : method);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = widget.settings;

    // Live values while sharing, otherwise the saved settings. Below Android 10
    // the name and password are random, so they're unknown until sharing starts.
    final running = _status.kind == ShareStatusKind.running;
    final custom = settings.customNetworkSupported;
    final ssid = running ? _status.ssid : (custom ? settings.fullSsid : null);
    final password = running
        ? _status.passphrase
        : (custom ? settings.passphrase : null);
    final host = running
        ? (_status.ownerIp ?? kDefaultOwnerIp)
        : kDefaultOwnerIp;
    final port = '${running ? _status.port ?? kDefaultPort : settings.port}';
    // Always offered; while sharing, only if its ports actually opened.
    final whatsApp = !running || _status.whatsAppProxy;

    return Scaffold(
      appBar: AppBar(title: Text(l.navConnect)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (running && ssid != null && password != null)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: WifiQrView(ssid: ssid, password: password, size: 180),
                ),
              )
            else
              _QrPlaceholder(onGoHome: widget.onGoHome),
            const SizedBox(height: 12),
            _RecommendedCard(onOpenReceive: widget.onOpenReceive),
            const SizedBox(height: 24),
            Text(l.withoutAppTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l.withoutAppSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            MethodCard(
              icon: Icons.wifi_rounded,
              title: l.guideProxyTitle,
              subtitle: l.guideProxySubtitle,
              expanded: _open == _Method.proxy,
              onToggle: () => _toggle(_Method.proxy),
              children: [
                _chips([
                  if (ssid != null) CopyChip(label: l.networkName, value: ssid),
                  if (password != null)
                    CopyChip(label: l.password, value: password),
                  CopyChip(label: l.chipHost, value: host),
                  CopyChip(label: l.chipPort, value: port),
                ]),
                const SizedBox(height: 16),
                for (final (i, step) in [
                  l.guideStep1(ssid ?? 'DIRECT-…'),
                  l.guideStep2(password ?? '…'),
                  l.guideStep3,
                  l.guideStep4(host, port),
                  l.guideStep5,
                ].indexed)
                  NumberedStep(number: i + 1, text: step),
              ],
            ),
            const SizedBox(height: 8),
            // Telegram ignores the system proxy but has its own SOCKS5 setting,
            // which Phone A's proxy port also speaks.
            MethodCard(
              icon: FontAwesomeIcons.telegram.data,
              title: l.guideTelegramTitle,
              subtitle: l.guideTelegramSubtitle,
              expanded: _open == _Method.telegram,
              onToggle: () => _toggle(_Method.telegram),
              children: [
                _chips([
                  CopyChip(label: l.chipHost, value: host),
                  CopyChip(label: l.chipPort, value: port),
                ]),
                const SizedBox(height: 12),
                Text(l.guideTelegram(host, port)),
              ],
            ),
            if (whatsApp) ...[
              const SizedBox(height: 8),
              MethodCard(
                icon: FontAwesomeIcons.whatsapp.data,
                title: l.guideWhatsAppTitle,
                subtitle: l.guideWhatsAppSubtitle,
                expanded: _open == _Method.whatsApp,
                onToggle: () => _toggle(_Method.whatsApp),
                children: [
                  _chips([
                    CopyChip(label: l.chipHost, value: host),
                    CopyChip(label: l.chipChatPort, value: _whatsAppChatPort),
                    CopyChip(label: l.chipMediaPort, value: _whatsAppMediaPort),
                  ]),
                  const SizedBox(height: 12),
                  Text(l.guideWhatsApp(host)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Apps that check the internet themselves need a DNS that answers;
            // Phone A's own address (handed out by Android) doesn't.
            MethodCard(
              icon: Icons.signal_wifi_connected_no_internet_4_rounded,
              title: l.guideDnsTitle,
              subtitle: l.guideDnsSubtitle,
              expanded: _open == _Method.dns,
              onToggle: () => _toggle(_Method.dns),
              children: [
                _chips([
                  CopyChip(label: l.chipDns1, value: host),
                  CopyChip(label: l.chipDns2, value: _publicDns),
                ]),
                const SizedBox(height: 12),
                Text(l.guideDnsTip(host)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              whatsApp ? l.guideNoteWithWhatsApp : l.guideNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(List<Widget> chips) =>
      Wrap(spacing: 8, runSpacing: 8, children: chips);
}

/// Shown in place of the QR while sharing is off.
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.qr_code_2,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              l.qrPlaceholder,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onGoHome,
              icon: const Icon(Icons.power_settings_new),
              label: Text(l.goToHome),
            ),
          ],
        ),
      ),
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
      margin: EdgeInsets.zero,
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
            FilledButton.icon(
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
