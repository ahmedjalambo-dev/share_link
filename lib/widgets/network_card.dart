import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'credential_tile.dart';

/// The running network at a glance: name and password, plus QR and guide shortcuts.
class NetworkCard extends StatelessWidget {
  const NetworkCard({
    super.key,
    required this.ssid,
    required this.password,
    required this.onShowQr,
    required this.onShowGuide,
  });

  final String ssid;
  final String password;
  final VoidCallback onShowQr;
  final VoidCallback onShowGuide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Column(
          children: [
            CredentialTile(icon: Icons.wifi, label: l.networkName, value: ssid),
            CredentialTile(icon: Icons.key, label: l.password, value: password),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShowQr,
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(l.showQr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onShowGuide,
                      icon: const Icon(Icons.help_outline),
                      label: Text(l.howToConnect),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
