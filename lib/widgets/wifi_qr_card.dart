import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../utils/format.dart';

/// QR code that lets Phone B join the Wi-Fi Direct network with its camera.
class WifiQrCard extends StatelessWidget {
  const WifiQrCard({super.key, required this.ssid, required this.password});

  final String ssid;
  final String password;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l.qrTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            // Always dark-on-white so it scans reliably in dark mode too.
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: wifiQrPayload(ssid, password),
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.qrCaption,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
