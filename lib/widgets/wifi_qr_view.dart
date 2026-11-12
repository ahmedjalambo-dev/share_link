import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../utils/format.dart';

/// QR code that lets Phone B join the Wi-Fi Direct network, with a title and caption.
class WifiQrView extends StatelessWidget {
  const WifiQrView({
    super.key,
    required this.ssid,
    required this.password,
    this.size = 220,
  });

  final String ssid;
  final String password;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.qrTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          ssid,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        // Always dark-on-white so it scans reliably in dark mode too.
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: wifiQrPayload(ssid, password),
              size: size,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.qrCaption,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
