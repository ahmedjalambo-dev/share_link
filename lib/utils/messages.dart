import '../l10n/app_localizations.dart';

/// Error codes sent by the native side (ErrorCodes in ShareState.kt, ClientErrorCodes in ClientState.kt).
abstract final class ErrorCode {
  // Sharing (Phone A)
  static const permissionDenied = 'permission_denied';
  static const locationDisabled = 'location_disabled';
  static const wifiDisabled = 'wifi_disabled';
  static const wifiNotConnected = 'wifi_not_connected';
  static const p2pUnsupported = 'p2p_unsupported';
  static const p2pBusy = 'p2p_busy';
  static const invalidSettings = 'invalid_settings';
  static const serviceFailed = 'service_failed';
  static const portInUse = 'port_in_use';
  static const proxyFailed = 'proxy_failed';

  // Client mode (Phone B)
  static const vpnDenied = 'vpn_denied';
  static const notOnDirectNetwork = 'not_on_direct_network';
  static const hostUnreachable = 'host_unreachable';
  static const vpnFailed = 'vpn_failed';
  static const connectionLost = 'connection_lost';

  // Settings validation
  static const invalidName = 'invalid_name';
  static const nameTooLong = 'name_too_long';
  static const invalidPassword = 'invalid_password';
  static const invalidPort = 'invalid_port';
}

/// Localized message for a sharing or client-mode error code.
String shareErrorMessage(AppLocalizations l, String? code) => switch (code) {
  ErrorCode.permissionDenied => l.errorPermissionDenied,
  ErrorCode.locationDisabled => l.errorLocationDisabled,
  ErrorCode.wifiDisabled => l.errorWifiDisabled,
  ErrorCode.wifiNotConnected => l.errorWifiNotConnected,
  ErrorCode.p2pUnsupported => l.errorP2pUnsupported,
  ErrorCode.p2pBusy => l.errorP2pBusy,
  ErrorCode.invalidSettings => l.errorInvalidSettings,
  ErrorCode.serviceFailed => l.errorServiceFailed,
  ErrorCode.portInUse => l.errorPortInUse,
  ErrorCode.proxyFailed => l.errorProxyFailed,
  ErrorCode.vpnDenied => l.errorVpnDenied,
  ErrorCode.notOnDirectNetwork => l.errorNotOnDirect,
  ErrorCode.hostUnreachable => l.errorHostUnreachable,
  ErrorCode.vpnFailed => l.errorVpnFailed,
  ErrorCode.connectionLost => l.errorConnectionLost,
  _ => l.errorGeneric,
};

/// Localized message for a settings validation error code.
String settingsErrorMessage(AppLocalizations l, String code) => switch (code) {
  ErrorCode.invalidName => l.errorInvalidName,
  ErrorCode.nameTooLong => l.errorNameTooLong,
  ErrorCode.invalidPassword => l.errorInvalidPassword,
  ErrorCode.invalidPort => l.errorInvalidPort,
  _ => l.errorGeneric,
};
