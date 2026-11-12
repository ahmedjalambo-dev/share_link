import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/share_channel.dart';
import '../utils/messages.dart';
import 'status_banner.dart';

/// Shows a localized error for a native error code, with a button to the settings screen that fixes it.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.code, this.detail});

  final String? code;
  final String? detail;

  /// Settings screen that fixes the error, if any.
  static (String, String)? _action(AppLocalizations l, String? code) =>
      switch (code) {
        ErrorCode.permissionDenied => (l.openAppSettings, 'app'),
        ErrorCode.locationDisabled => (l.openLocationSettings, 'location'),
        ErrorCode.wifiDisabled ||
        ErrorCode.wifiNotConnected ||
        ErrorCode.notOnDirectNetwork ||
        ErrorCode.joinFailed => (l.openWifiSettings, 'wifi'),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final action = _action(l, code);
    return StatusBanner(
      icon: Icons.error_outline,
      message: shareErrorMessage(l, code),
      detail: detail,
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      actionLabel: action?.$1,
      onAction: action == null
          ? null
          : () => ShareChannel.openSystemSettings(action.$2),
    );
  }
}
