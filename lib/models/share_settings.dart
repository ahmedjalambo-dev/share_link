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
    required this.customNetworkSupported,
  });

  factory ShareSettingsData.fromMap(Map<Object?, Object?> map) {
    return ShareSettingsData(
      ssidPrefix: map['ssidPrefix'] as String? ?? 'DIRECT-',
      networkName: map['networkName'] as String? ?? '',
      passphrase: map['passphrase'] as String? ?? '',
      port: map['port'] as int? ?? 8282,
      language: map['language'] as String? ?? 'system',
      mode: map['mode'] as String? ?? 'share',
      clientPort: map['clientPort'] as int? ?? 8282,
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

  /// Custom name/password need Android 10+; older versions get an auto-generated group.
  final bool customNetworkSupported;

  String get fullSsid => ssidPrefix + networkName;
}
