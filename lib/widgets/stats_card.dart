import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/format.dart';

/// Live speed, session totals and session time; [connections] is omitted in client mode.
class StatsCard extends StatefulWidget {
  const StatsCard({
    super.key,
    this.connections,
    required this.bytesUp,
    required this.bytesDown,
    required this.speedUp,
    required this.speedDown,
    required this.startedAt,
  });

  final int? connections;
  final int bytesUp;
  final int bytesDown;
  final int speedUp;
  final int speedDown;
  final DateTime? startedAt;

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _syncClock();
  }

  @override
  void didUpdateWidget(StatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncClock();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /// Native only sends changes, so the session time ticks on its own timer.
  void _syncClock() {
    if (widget.startedAt == null) {
      _clock?.cancel();
      _clock = null;
    } else {
      _clock ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final startedAt = widget.startedAt;
    final elapsed = startedAt == null
        ? null
        : DateTime.now().difference(startedAt);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                _SpeedTile(
                  icon: Icons.arrow_downward,
                  label: l.download,
                  speed: widget.speedDown,
                  total: widget.bytesDown,
                ),
                _SpeedTile(
                  icon: Icons.arrow_upward,
                  label: l.upload,
                  speed: widget.speedUp,
                  total: widget.bytesUp,
                ),
              ],
            ),
            if (elapsed != null || widget.connections != null) ...[
              const Divider(height: 24, indent: 8, endIndent: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (elapsed != null)
                    _Fact(
                      icon: Icons.timer_outlined,
                      value: formatDuration(
                        elapsed.isNegative ? Duration.zero : elapsed,
                      ),
                      label: l.sessionTime,
                    ),
                  if (widget.connections != null)
                    _Fact(
                      icon: Icons.link,
                      value: '${widget.connections}',
                      label: l.connections,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One direction: label, live speed (large) and this session's total.
class _SpeedTile extends StatelessWidget {
  const _SpeedTile({
    required this.icon,
    required this.label,
    required this.speed,
    required this.total,
  });

  final IconData icon;
  final String label;
  final int speed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Shrinks rather than overflows on narrow screens.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatSpeed(speed),
              style: theme.textTheme.titleLarge,
              textDirection: TextDirection.ltr,
            ),
          ),
          Text(
            l.totalAmount(formatBytes(total)),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// A small icon + value + label pair under the speeds.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
