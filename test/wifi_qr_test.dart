import 'package:flutter_test/flutter_test.dart';
import 'package:share_link/utils/format.dart';
import 'package:share_link/utils/wifi_qr.dart';

void main() {
  test('parses Phone A\'s standard QR', () {
    final data = parseWifiQr('WIFI:T:WPA;S:DIRECT-ab-ShareLink;P:secret123;;');
    expect(data?.ssid, 'DIRECT-ab-ShareLink');
    expect(data?.password, 'secret123');
    expect(data?.isShareLinkNetwork, isTrue);
  });

  test('accepts any field order, lowercase prefix and extra fields', () {
    final data = parseWifiQr(
      'wifi:P:secret123;H:false;S:DIRECT-xy-Net;T:WPA;;',
    );
    expect(data?.ssid, 'DIRECT-xy-Net');
    expect(data?.password, 'secret123');
  });

  test('round-trips wifiQrPayload, including escaped characters', () {
    const ssid = r'DIRECT-ab-a;b,c:d"e\f';
    const password = r'p;w:x\y,z"1';
    final data = parseWifiQr(wifiQrPayload(ssid, password));
    expect(data?.ssid, ssid);
    expect(data?.password, password);
  });

  test('rejects text that is not a Wi-Fi QR code', () {
    expect(parseWifiQr('https://example.com'), isNull);
    expect(parseWifiQr(''), isNull);
    expect(parseWifiQr('WIFI:T:WPA;P:secret123;;'), isNull); // no network name
  });

  test('isShareLinkNetwork needs a DIRECT- name and a valid password', () {
    expect(
      const WifiQrData(
        ssid: 'HomeWifi',
        password: 'secret123',
      ).isShareLinkNetwork,
      isFalse,
    );
    expect(
      const WifiQrData(
        ssid: 'DIRECT-ab-X',
        password: 'short',
      ).isShareLinkNetwork,
      isFalse,
    );
    expect(
      const WifiQrData(ssid: 'DIRECT-ab-X', password: '').isShareLinkNetwork,
      isFalse,
    );
  });
}
