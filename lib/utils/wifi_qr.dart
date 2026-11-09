/// Network name and password read from a standard Wi-Fi QR code
/// (`WIFI:T:WPA;S:<ssid>;P:<password>;;`), as Phone A shows it.
class WifiQrData {
  const WifiQrData({required this.ssid, required this.password});

  final String ssid;
  final String password;

  /// True for Phone A's Wi-Fi Direct network with a usable WPA2 password.
  bool get isShareLinkNetwork =>
      ssid.startsWith('DIRECT-') &&
      password.length >= 8 &&
      password.length <= 63 &&
      password.codeUnits.every((c) => c >= 32 && c <= 126);
}

/// Parses a Wi-Fi QR code; the inverse of `wifiQrPayload` in format.dart.
///
/// Accepts any letter case for `WIFI:`, any field order, and the escapes
/// `\;` `\,` `\:` `\\` `\"`. Unknown fields (e.g. `H:` for hidden) are
/// ignored. Returns null if it isn't a Wi-Fi code or has no network name.
WifiQrData? parseWifiQr(String raw) {
  final text = raw.trim();
  if (!text.toUpperCase().startsWith('WIFI:')) return null;

  final fields = <String, String>{};
  final current = StringBuffer();
  var escaped = false;
  for (final char in text.substring(5).split('')) {
    if (escaped) {
      current.write(char);
      escaped = false;
    } else if (char == r'\') {
      escaped = true;
    } else if (char == ';') {
      _addField(fields, current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  _addField(fields, current.toString());

  final ssid = fields['S'];
  if (ssid == null || ssid.isEmpty) return null;
  return WifiQrData(ssid: ssid, password: fields['P'] ?? '');
}

/// Adds one `KEY:value` field; the value may itself contain unescaped colons.
void _addField(Map<String, String> fields, String field) {
  final colon = field.indexOf(':');
  if (colon <= 0) return;
  final key = field.substring(0, colon).toUpperCase();
  fields.putIfAbsent(key, () => field.substring(colon + 1));
}
