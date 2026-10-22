import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/format.dart';

/// Live traffic counters; [connections] is omitted in client mode.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    this.connections,
    required this.bytesUp,
    required this.bytesDown,
  });

  final int? connections;
  final int bytesUp;
  final int bytesDown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            if (connections != null)
              _stat(context, Icons.link, l.connections, '$connections'),
            _stat(context, Icons.arrow_upward, l.upload, formatBytes(bytesUp)),
            _stat(
              context,
              Icons.arrow_downward,
              l.download,
              formatBytes(bytesDown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium,
            textDirection: TextDirection.ltr,
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
