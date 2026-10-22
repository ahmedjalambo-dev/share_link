import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/share_channel.dart';
import '../utils/messages.dart';

/// Shows a localized error for a native error code, with a button to the settings screen that fixes it.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.code, this.detail});

  final String? code;
  final String? detail;

  /// Settings screen that fixes the error, if any.
  static (String, String)? _action(AppLocalizations l, String? code) =>
      switch (code) {
        'permission_denied' => (l.openAppSettings, 'app'),
        'location_disabled' => (l.openLocationSettings, 'location'),
        'wifi_disabled' ||
        'wifi_not_connected' ||
        'not_on_direct_network' => (l.openWifiSettings, 'wifi'),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final action = _action(l, code);
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shareErrorMessage(l, code),
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textDirection: TextDirection.ltr,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
              ),
            ],
            if (action != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => ShareChannel.openSystemSettings(action.$2),
                  child: Text(action.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
