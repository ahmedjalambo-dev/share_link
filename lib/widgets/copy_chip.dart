import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// A labelled value (host, port, password…) that copies itself when tapped.
class CopyChip extends StatelessWidget {
  const CopyChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ActionChip(
      avatar: const Icon(Icons.copy, size: 16),
      tooltip: l.copy,
      label: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label  '),
            // Values are always LTR, even in an RTL layout.
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.copied(label))));
      },
    );
  }
}
