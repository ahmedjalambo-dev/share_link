import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Step-by-step instructions for Phone B, filled in with the current values.
class ConnectGuide extends StatelessWidget {
  const ConnectGuide({
    super.key,
    required this.ssid,
    required this.password,
    required this.host,
    required this.port,
    this.initiallyExpanded = false,
  });

  final String ssid;
  final String password;
  final String host;
  final String port;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final steps = [
      l.guideStep1(ssid),
      l.guideStep2(password),
      l.guideStep3,
      l.guideStep4(host, port),
      l.guideStep5,
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: Text(l.guideTitle),
        initiallyExpanded: initiallyExpanded,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(l.guideRecommended),
              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.guideManualTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (var i = 0; i < steps.length; i++)
            _GuideStep(number: i + 1, text: steps[i]),
          const SizedBox(height: 4),
          Text(
            l.guideNote,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text('$number', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
