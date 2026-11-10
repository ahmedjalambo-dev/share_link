enum ClientStatusKind {
  disconnected,
  connecting,
  connected,

  /// Phone A dropped; the VPN stays up and the app keeps retrying until DISCONNECT.
  reconnecting,
  error,
}

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
    this.reconnectAttempt = 0,
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
      reconnectAttempt: map['reconnectAttempt'] as int? ?? 0,
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

  /// Retry number while [ClientStatusKind.reconnecting]; [errorCode] then holds
  /// the last attempt's failure.
  final int reconnectAttempt;

  bool get isActive =>
      kind == ClientStatusKind.connecting ||
      kind == ClientStatusKind.connected ||
      kind == ClientStatusKind.reconnecting;
}
