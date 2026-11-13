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

/// Live speed, never smaller than KB/s, e.g. `0 KB/s`, `85 KB/s`, `1.2 MB/s`.
String formatSpeed(int bytesPerSecond) {
  final kb = bytesPerSecond / 1024;
  if (kb >= 1024) {
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB/s';
  }
  // One decimal only for slow trickles, so the number doesn't jitter.
  final digits = kb > 0 && kb < 10 ? 1 : 0;
  return '${kb.toStringAsFixed(digits)} KB/s';
}

/// Session length as a clock, e.g. `4:05` or `1:02:33`.
String formatDuration(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60);
  final seconds = two(duration.inSeconds.remainder(60));
  return duration.inHours > 0
      ? '${duration.inHours}:${two(minutes)}:$seconds'
      : '$minutes:$seconds';
}

/// Standard Wi-Fi QR payload understood by Android and iOS camera apps.
String wifiQrPayload(String ssid, String password) =>
    'WIFI:T:WPA;S:${_escapeQr(ssid)};P:${_escapeQr(password)};;';

String _escapeQr(String value) =>
    value.replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');
