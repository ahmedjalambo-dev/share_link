import 'package:flutter/material.dart';

/// Slim colored banner: an icon, a message (plus optional detail) and an optional action.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;

  /// Technical detail, shown small and always left-to-right.
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: background,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      textDirection: TextDirection.ltr,
                      style: textTheme.bodySmall?.copyWith(color: foreground),
                    ),
                ],
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
