import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licences of bundled assets and native code that Flutter's licence page
/// doesn't know about: the fonts and the VPN tunnel library.
const _licenses = {
  'IBM Plex Sans': 'assets/fonts/IBM_Plex_Sans/OFL.txt',
  'IBM Plex Sans Arabic': 'assets/fonts/IBM_Plex_Sans_Arabic/OFL.txt',
  'hev-socks5-tunnel': 'assets/licenses/hev-socks5-tunnel.txt',
  'hev-task-system': 'assets/licenses/hev-task-system.txt',
  'lwIP': 'assets/licenses/lwip.txt',
  'yaml': 'assets/licenses/yaml.txt',
};

void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: package, value: path) in _licenses.entries) {
      yield LicenseEntryWithLineBreaks([
        package,
      ], await rootBundle.loadString(path));
    }
  });
}
