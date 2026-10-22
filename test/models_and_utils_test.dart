import 'package:flutter_test/flutter_test.dart';
import 'package:share_link/models/client_status.dart';
import 'package:share_link/models/share_settings.dart';
import 'package:share_link/utils/constants.dart';
import 'package:share_link/models/share_status.dart';
import 'package:share_link/utils/format.dart';

void main() {
  test('ShareStatus parses a running snapshot', () {
    final status = ShareStatus.fromMap({
      'status': 'running',
      'ssid': 'DIRECT-ab-ShareLink',
      'passphrase': 'secret123',
      'ownerIp': '192.168.49.1',
      'port': 8282,
    });

    expect(status.kind, ShareStatusKind.running);
    expect(status.isActive, isTrue);
    expect(status.ssid, 'DIRECT-ab-ShareLink');
    expect(status.port, 8282);
    expect(status.activeConnections, 0);
    expect(status.upstreamAvailable, isTrue);
  });

  test('ShareStatus parses proxy stats', () {
    final status = ShareStatus.fromMap({
      'status': 'running',
      'activeConnections': 3,
      'bytesUp': 2048,
      'bytesDown': 5 * 1024 * 1024,
      'upstreamAvailable': false,
    });
    expect(status.activeConnections, 3);
    expect(status.bytesDown, 5 * 1024 * 1024);
    expect(status.upstreamAvailable, isFalse);
  });

  test('ShareStatus falls back to stopped for unknown values', () {
    final status = ShareStatus.fromMap({'status': 'weird'});
    expect(status.kind, ShareStatusKind.stopped);
    expect(status.isActive, isFalse);
  });

  test('ClientStatus parses a connected snapshot', () {
    final status = ClientStatus.fromMap({
      'status': 'connected',
      'host': '192.168.49.1',
      'port': 8282,
      'bytesUp': 100,
      'bytesDown': 2000,
    });
    expect(status.kind, ClientStatusKind.connected);
    expect(status.isActive, isTrue);
    expect(status.host, '192.168.49.1');
    expect(status.bytesDown, 2000);
  });

  test('ClientStatus defaults to disconnected', () {
    final status = ClientStatus.fromMap({'status': 'error', 'errorCode': 'x'});
    expect(status.kind, ClientStatusKind.error);
    expect(status.isActive, isFalse);
    expect(ClientStatus.fromMap({}).kind, ClientStatusKind.disconnected);
  });

  test('ClientStatus parses the joining flag', () {
    expect(
      ClientStatus.fromMap({'status': 'connecting', 'joining': true}).joining,
      isTrue,
    );
    expect(ClientStatus.fromMap({'status': 'connecting'}).joining, isFalse);
  });

  test('ShareSettingsData parses client-mode fields', () {
    final settings = ShareSettingsData.fromMap({
      'clientPort': 9000,
      'clientSsid': 'DIRECT-ab-ShareLink',
      'clientPassphrase': 'secret123',
      'clientAutoJoin': false,
      'apiLevel': 28,
    });
    expect(settings.clientPort, 9000);
    expect(settings.clientSsid, 'DIRECT-ab-ShareLink');
    expect(settings.clientPassphrase, 'secret123');
    expect(settings.clientAutoJoin, isFalse);
    expect(settings.canPickNetwork, isFalse);
  });

  test(
    'ShareSettingsData defaults: auto-join on, defaults for missing values',
    () {
      final settings = ShareSettingsData.fromMap({'apiLevel': 34});
      expect(settings.clientAutoJoin, isTrue);
      expect(settings.clientSsid, '');
      expect(settings.clientPort, kDefaultPort);
      expect(settings.canPickNetwork, isTrue);
    },
  );

  test('formatBytes picks a readable unit', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatBytes(200 * 1024 * 1024), '200 MB');
  });

  test('wifiQrPayload builds a WPA QR string', () {
    expect(
      wifiQrPayload('DIRECT-ab-ShareLink', 'secret123'),
      'WIFI:T:WPA;S:DIRECT-ab-ShareLink;P:secret123;;',
    );
  });

  test('wifiQrPayload escapes special characters', () {
    expect(
      wifiQrPayload(r'a;b,c:d"e\f', 'p;w'),
      r'WIFI:T:WPA;S:a\;b\,c\:d\"e\\f;P:p\;w;;',
    );
  });
}
