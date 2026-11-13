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
    this.speedUp = 0,
    this.speedDown = 0,
    this.startedAt,
    this.upstreamAvailable = true,
    this.whatsAppProxy = false,
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
      speedUp: map['speedUp'] as int? ?? 0,
      speedDown: map['speedDown'] as int? ?? 0,
      startedAt: _time(map['startedAt']),
      upstreamAvailable: map['upstreamAvailable'] as bool? ?? true,
      whatsAppProxy: map['whatsAppProxy'] == true,
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

  /// Bytes per second over the last native stats tick.
  final int speedUp;
  final int speedDown;

  /// When this session started; null until running.
  final DateTime? startedAt;

  /// False while Phone A's Wi-Fi is down (the proxy keeps running).
  final bool upstreamAvailable;

  /// The experimental WhatsApp proxy ports are open on Phone A.
  final bool whatsAppProxy;

  /// True while the service is starting or running (the button acts as "Stop").
  bool get isActive =>
      kind == ShareStatusKind.starting || kind == ShareStatusKind.running;
}

DateTime? _time(Object? epochMs) =>
    epochMs is int ? DateTime.fromMillisecondsSinceEpoch(epochMs) : null;
