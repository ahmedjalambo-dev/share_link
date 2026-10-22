enum ShareStatusKind { stopped, starting, running, error }

/// Snapshot of the native sharing state, as sent over the status EventChannel.
class ShareStatus {
  const ShareStatus({
    required this.kind,
    this.ssid,
    this.passphrase,
    this.ownerIp,
    this.port,
    this.errorCode,
    this.errorDetail,
    this.activeConnections = 0,
    this.bytesUp = 0,
    this.bytesDown = 0,
    this.upstreamAvailable = true,
  });

  static const stopped = ShareStatus(kind: ShareStatusKind.stopped);

  factory ShareStatus.fromMap(Map<Object?, Object?> map) {
    return ShareStatus(
      kind:
          ShareStatusKind.values.asNameMap()[map['status']] ??
          ShareStatusKind.stopped,
      ssid: map['ssid'] as String?,
      passphrase: map['passphrase'] as String?,
      ownerIp: map['ownerIp'] as String?,
      port: map['port'] as int?,
      errorCode: map['errorCode'] as String?,
      errorDetail: map['errorDetail'] as String?,
      activeConnections: map['activeConnections'] as int? ?? 0,
      bytesUp: map['bytesUp'] as int? ?? 0,
      bytesDown: map['bytesDown'] as int? ?? 0,
      upstreamAvailable: map['upstreamAvailable'] as bool? ?? true,
    );
  }

  final ShareStatusKind kind;
  final String? ssid;
  final String? passphrase;
  final String? ownerIp;
  final int? port;
  final String? errorCode;
  final String? errorDetail;
  final int activeConnections;
  final int bytesUp;
  final int bytesDown;

  /// False while Phone A's Wi-Fi is down (the proxy keeps running).
  final bool upstreamAvailable;

  /// True while the service is starting or running (the button acts as "Stop").
  bool get isActive =>
      kind == ShareStatusKind.starting || kind == ShareStatusKind.running;
}
