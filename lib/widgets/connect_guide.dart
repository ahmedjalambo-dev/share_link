import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'numbered_step.dart';

/// Step-by-step instructions for Phone B, filled in with the current values.
class ConnectGuide extends StatelessWidget {
  const ConnectGuide({
    super.key,
    required this.ssid,
    required this.password,
    required this.host,
    required this.port,
    this.initiallyExpanded = false,
    this.whatsAppProxy = false,
  });

  final String ssid;
  final String password;
  final String host;
  final String port;
  final bool initiallyExpanded;

  /// Show how to use Phone A as a WhatsApp proxy (false only if its ports failed to open).
  final bool whatsAppProxy;

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
            NumberedStep(number: i + 1, text: steps[i]),
          // Telegram ignores the system proxy but has its own SOCKS5 setting,
          // which Phone A's proxy port also speaks.
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.send),
              title: Text(l.guideTelegramTitle),
              subtitle: Text(l.guideTelegram(host, port)),
            ),
          ),
          if (whatsAppProxy)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.chat),
                title: Text(l.guideWhatsAppTitle),
                subtitle: Text(l.guideWhatsApp(host)),
              ),
            ),
          // Apps that check the internet themselves need a DNS that answers;
          // Phone A's own address (handed out by Android) doesn't.
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.dns),
              title: Text(l.guideDnsTitle),
              subtitle: Text(l.guideDnsTip(host)),
            ),
          ),
          Text(
            whatsAppProxy ? l.guideNoteWithWhatsApp : l.guideNote,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
