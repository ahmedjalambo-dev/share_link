import '../utils/constants.dart';

/// User settings stored on the native side (see ShareSettings.kt).
class ShareSettingsData {
  const ShareSettingsData({
    required this.ssidPrefix,
    required this.networkName,
    required this.passphrase,
    required this.port,
    required this.language,
    required this.mode,
    required this.clientPort,
    required this.clientSsid,
    required this.clientPassphrase,
    required this.clientAutoJoin,
    required this.apiLevel,
    required this.customNetworkSupported,
  });

  factory ShareSettingsData.fromMap(Map<Object?, Object?> map) {
    return ShareSettingsData(
      ssidPrefix: map['ssidPrefix'] as String? ?? 'DIRECT-',
      networkName: map['networkName'] as String? ?? '',
      passphrase: map['passphrase'] as String? ?? '',
      port: map['port'] as int? ?? kDefaultPort,
      language: map['language'] as String? ?? 'system',
      mode: map['mode'] as String? ?? 'share',
      clientPort: map['clientPort'] as int? ?? kDefaultPort,
      clientSsid: map['clientSsid'] as String? ?? '',
      clientPassphrase: map['clientPassphrase'] as String? ?? '',
      clientAutoJoin: map['clientAutoJoin'] != false,
      apiLevel: map['apiLevel'] as int? ?? 0,
      customNetworkSupported: map['customNetworkSupported'] == true,
    );
  }

  /// "DIRECT-xy-", required by Android for custom group names.
  final String ssidPrefix;
  final String networkName;
  final String passphrase;
  final int port;

  /// `system`, `en` or `ar`.
  final String language;

  /// Home screen mode: `share` (Phone A) or `connect` (Phone B).
  final String mode;

  /// Phone A's proxy port, as last entered on Phone B.
  final int clientPort;

  /// Phone A's network name as entered on Phone B; may be empty from Android 10
  /// (Android then shows a list of DIRECT- networks).
  final String clientSsid;
  final String clientPassphrase;

  /// Join Phone A's network from the app when CONNECT is tapped.
  final bool clientAutoJoin;

  /// Android API level of this phone.
  final int apiLevel;

  /// Android 10+ can show a network picker, so the network name is optional.
  bool get canPickNetwork => apiLevel >= 29;

  /// Custom name/password need Android 10+; older versions get an auto-generated group.
  final bool customNetworkSupported;

  String get fullSsid => ssidPrefix + networkName;
}
