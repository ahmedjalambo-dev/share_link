import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// One labelled value (network name, password, IP, port) with a copy button.
class CredentialTile extends StatelessWidget {
  const CredentialTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: theme.textTheme.labelMedium),
      subtitle: SelectableText(
        value,
        // Credentials are always LTR, even in an RTL layout.
        textDirection: TextDirection.ltr,
        style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        tooltip: l.copy,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.copied(label))));
        },
      ),
    );
  }
}
