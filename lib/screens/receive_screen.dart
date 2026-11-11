import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/share_settings.dart';
import '../widgets/client_panel.dart';

/// Receive mode (Phone B with the app): its own page, opened from the Connect tab.
class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key, required this.settings});

  final ShareSettingsData settings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.receiveTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [ClientPanel(settings: settings)],
        ),
      ),
    );
  }
}
