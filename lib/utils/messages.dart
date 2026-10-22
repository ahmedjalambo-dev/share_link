import '../l10n/app_localizations.dart';

/// Localized message for a native sharing error code (see ErrorCodes in ShareState.kt).
String shareErrorMessage(AppLocalizations l, String? code) => switch (code) {
  'permission_denied' => l.errorPermissionDenied,
  'location_disabled' => l.errorLocationDisabled,
  'wifi_disabled' => l.errorWifiDisabled,
  'wifi_not_connected' => l.errorWifiNotConnected,
  'p2p_unsupported' => l.errorP2pUnsupported,
  'p2p_busy' => l.errorP2pBusy,
  'invalid_settings' => l.errorInvalidSettings,
  'service_failed' => l.errorServiceFailed,
  'port_in_use' => l.errorPortInUse,
  'proxy_failed' => l.errorProxyFailed,
  // Client mode (ClientErrorCodes in ClientState.kt)
  'vpn_denied' => l.errorVpnDenied,
  'not_on_direct_network' => l.errorNotOnDirect,
  'host_unreachable' => l.errorHostUnreachable,
  'vpn_failed' => l.errorVpnFailed,
  'connection_lost' => l.errorConnectionLost,
  _ => l.errorGeneric,
};

/// Localized message for a settings validation error code (see ShareSettings.save).
String settingsErrorMessage(AppLocalizations l, String code) => switch (code) {
  'invalid_name' => l.errorInvalidName,
  'name_too_long' => l.errorNameTooLong,
  'invalid_password' => l.errorInvalidPassword,
  'invalid_port' => l.errorInvalidPort,
  _ => l.errorGeneric,
};
