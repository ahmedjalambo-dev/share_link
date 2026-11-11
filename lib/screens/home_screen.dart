import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/share_panel.dart';

/// Home tab: sharing this phone's Wi-Fi (Phone A).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.receiving,
    required this.onOpenReceive,
  });

  /// Receive mode is active on this phone.
  final bool receiving;

  /// Opens the Receive screen (from the "receiving" banner).
  final VoidCallback onOpenReceive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (receiving) ...[
              _ReceivingBanner(onOpen: onOpenReceive),
              const SizedBox(height: 16),
            ],
            SharePanel(receiving: receiving),
          ],
        ),
      ),
    );
  }
}

/// Shown while this phone is getting internet from another phone (Receive mode).
class _ReceivingBanner extends StatelessWidget {
  const _ReceivingBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: ListTile(
        leading: Icon(Icons.vpn_lock, color: scheme.onSecondaryContainer),
        title: Text(
          l.receivingBanner,
          style: TextStyle(color: scheme.onSecondaryContainer),
        ),
        trailing: TextButton(onPressed: onOpen, child: Text(l.open)),
      ),
    );
  }
}
