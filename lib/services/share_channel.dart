import 'package:flutter/services.dart';

import '../models/client_status.dart';
import '../models/share_settings.dart';
import '../models/share_status.dart';

class PermissionResult {
  const PermissionResult({
    required this.granted,
    required this.notificationsGranted,
    required this.permanentlyDenied,
  });

  factory PermissionResult.fromMap(Map<Object?, Object?> map) {
    return PermissionResult(
      granted: map['granted'] == true,
      notificationsGranted: map['notificationsGranted'] == true,
      permanentlyDenied: map['permanentlyDenied'] == true,
    );
  }

  final bool granted;
  final bool notificationsGranted;
  final bool permanentlyDenied;
}

/// Thin wrapper over the native MethodChannel (commands) and EventChannel (status).
class ShareChannel {
  static const _control = MethodChannel('share_link/control');
  static const _status = EventChannel('share_link/status');
  static const _clientStatus = EventChannel('share_link/client_status');

  static final Stream<ShareStatus> statusStream = _status
      .receiveBroadcastStream()
      .map((event) => ShareStatus.fromMap(event as Map<Object?, Object?>));

  static Future<ShareStatus> getStatus() async {
    final map = await _control.invokeMapMethod<Object?, Object?>('getStatus');
    return map == null ? ShareStatus.stopped : ShareStatus.fromMap(map);
  }

  /// Returns false if a pre-start check failed; the reason arrives on [statusStream].
  static Future<bool> start() async =>
      await _control.invokeMethod<bool>('start') ?? false;

  static Future<void> stop() => _control.invokeMethod<void>('stop');

  static Future<PermissionResult> checkPermissions() async {
    final map = await _control.invokeMapMethod<Object?, Object?>(
      'checkPermissions',
    );
    return PermissionResult.fromMap(map ?? const {});
  }

  static Future<PermissionResult> requestPermissions() async {
    final map = await _control.invokeMapMethod<Object?, Object?>(
      'requestPermissions',
    );
    return PermissionResult.fromMap(map ?? const {});
  }

  /// [target] is one of `location`, `wifi` or `app`.
  static Future<void> openSystemSettings(String target) =>
      _control.invokeMethod<void>('openSystemSettings', {'target': target});

  /// Stops sharing, waits for the service to wind down, then starts again.
  static Future<void> restart() async {
    await stop();
    for (var i = 0; i < 25; i++) {
      if (!(await getStatus()).isActive) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await start();
  }

  static Future<ShareSettingsData> getSettings() async {
    final map = await _control.invokeMapMethod<Object?, Object?>('getSettings');
    return ShareSettingsData.fromMap(map ?? const {});
  }

  /// Throws a [PlatformException] whose code is `invalid_name`, `name_too_long`,
  /// `invalid_password` or `invalid_port` when validation fails.
  static Future<ShareSettingsData> saveSettings({
    required String networkName,
    required String passphrase,
    required int port,
  }) async {
    final map = await _control.invokeMapMethod<Object?, Object?>(
      'saveSettings',
      {'networkName': networkName, 'passphrase': passphrase, 'port': port},
    );
    return ShareSettingsData.fromMap(map ?? const {});
  }

  /// [language] is `system`, `en` or `ar`.
  static Future<void> setLanguage(String language) =>
      _control.invokeMethod<void>('setLanguage', {'language': language});

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await _control.invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
      false;

  static Future<void> requestIgnoreBatteryOptimizations() =>
      _control.invokeMethod<void>('requestIgnoreBatteryOptimizations');

  /// [mode] is `share` or `connect`.
  static Future<void> setMode(String mode) =>
      _control.invokeMethod<void>('setMode', {'mode': mode});

  // Client mode (Phone B)

  static final Stream<ClientStatus> clientStatusStream = _clientStatus
      .receiveBroadcastStream()
      .map((event) => ClientStatus.fromMap(event as Map<Object?, Object?>));

  /// Shows Android's VPN "Connection request" dialog if needed; true when allowed.
  static Future<bool> prepareVpn() async =>
      await _control.invokeMethod<bool>('prepareVpn') ?? false;

  /// Returns false if the VPN isn't allowed; progress arrives on [clientStatusStream].
  static Future<bool> connectClient(int port) async =>
      await _control.invokeMethod<bool>('connectClient', {'port': port}) ??
      false;

  static Future<void> disconnectClient() =>
      _control.invokeMethod<void>('disconnectClient');
}
