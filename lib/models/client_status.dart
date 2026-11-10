enum ClientStatusKind { disconnected, connecting, connected, error }

/// Snapshot of client mode (Phone B), as sent over the client status EventChannel.
class ClientStatus {
  const ClientStatus({
    required this.kind,
    this.host,
    this.port,
    this.bytesUp = 0,
    this.bytesDown = 0,
    this.errorCode,
    this.errorDetail,
    this.joining = false,
  });

  static const disconnected = ClientStatus(kind: ClientStatusKind.disconnected);

  factory ClientStatus.fromMap(Map<Object?, Object?> map) {
    return ClientStatus(
      kind:
          ClientStatusKind.values.asNameMap()[map['status']] ??
          ClientStatusKind.disconnected,
      host: map['host'] as String?,
      port: map['port'] as int?,
      bytesUp: map['bytesUp'] as int? ?? 0,
      bytesDown: map['bytesDown'] as int? ?? 0,
      errorCode: map['errorCode'] as String?,
      errorDetail: map['errorDetail'] as String?,
      joining: map['joining'] == true,
    );
  }

  final ClientStatusKind kind;

  /// Phone A's address, detected from the Wi-Fi Direct network.
  final String? host;
  final int? port;
  final int bytesUp;
  final int bytesDown;
  final String? errorCode;
  final String? errorDetail;

  /// True while connecting and the app is joining Phone A's Wi-Fi itself.
  final bool joining;

  bool get isActive =>
      kind == ClientStatusKind.connecting || kind == ClientStatusKind.connected;
}
