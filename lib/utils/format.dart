/// Human-readable byte count, e.g. `1.4 MB`.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 || value >= 100 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// Standard Wi-Fi QR payload understood by Android and iOS camera apps.
String wifiQrPayload(String ssid, String password) =>
    'WIFI:T:WPA;S:${_escapeQr(ssid)};P:${_escapeQr(password)};;';

String _escapeQr(String value) =>
    value.replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');
