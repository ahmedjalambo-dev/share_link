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
    this.devices = const [],
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
      devices: [
        for (final device in map['devices'] as List<Object?>? ?? const [])
          if (device is Map) ConnectedDevice.fromMap(device),
      ],
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

  /// Every device that used the internet this session, active ones first.
  final List<ConnectedDevice> devices;

  /// True while the service is starting or running (the button acts as "Stop").
  bool get isActive =>
      kind == ShareStatusKind.starting || kind == ShareStatusKind.running;
}

/// One phone using the shared internet, told apart by its address.
class ConnectedDevice {
  const ConnectedDevice({
    required this.address,
    this.name,
    this.nickname,
    this.bytesUp = 0,
    this.bytesDown = 0,
    this.speedUp = 0,
    this.speedDown = 0,
    this.connections = 0,
    this.blocked = false,
  });

  factory ConnectedDevice.fromMap(Map<Object?, Object?> map) {
    return ConnectedDevice(
      address: map['address'] as String? ?? '',
      name: map['name'] as String?,
      nickname: map['nickname'] as String?,
      bytesUp: map['bytesUp'] as int? ?? 0,
      bytesDown: map['bytesDown'] as int? ?? 0,
      speedUp: map['speedUp'] as int? ?? 0,
      speedDown: map['speedDown'] as int? ?? 0,
      connections: map['connections'] as int? ?? 0,
      blocked: map['blocked'] == true,
    );
  }

  final String address;

  /// The phone's own name or model, when it could be found.
  final String? name;

  /// The name the user gave it on this phone.
  final String? nickname;
  final int bytesUp;
  final int bytesDown;
  final int speedUp;
  final int speedDown;

  /// Open connections right now.
  final int connections;

  /// Disconnected by the user: no internet until allowed again.
  final bool blocked;

  /// The nickname, else the phone's own name; null when neither is known.
  String? get displayName => nickname ?? name;

  bool get active => connections > 0 && !blocked;
}

DateTime? _time(Object? epochMs) =>
    epochMs is int ? DateTime.fromMillisecondsSinceEpoch(epochMs) : null;
