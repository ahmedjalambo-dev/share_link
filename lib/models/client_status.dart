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

  bool get isActive =>
      kind == ClientStatusKind.connecting || kind == ClientStatusKind.connected;
}
