import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/client_status.dart';
import '../models/share_settings.dart';
import '../services/share_channel.dart';
import 'connect_tab.dart';
import 'home_screen.dart';
import 'receive_screen.dart';
import 'settings_screen.dart';

/// Top-level layout: bottom navigation between Home, Connect a device and Settings.
/// Tabs live in an [IndexedStack], so each keeps its state when switching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _homeTab = 0;
  static const _connectTab = 1;
  static const _settingsTab = 2;

  int _index = 0;
  ShareSettingsData? _settings;
  ClientStatus _client = ClientStatus.disconnected;
  StreamSubscription<ClientStatus>? _clientSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    ShareChannel.getClientStatus().then((status) {
      if (mounted) setState(() => _client = status);
    });
    _clientSubscription = ShareChannel.clientStatusStream.listen(
      (status) => setState(() => _client = status),
    );
  }

  @override
  void dispose() {
    _clientSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ShareChannel.getSettings();
    if (mounted) setState(() => _settings = settings);
  }

  void _select(int index) {
    // Leaving Settings: pick up any changed name, password or port.
    if (_index == _settingsTab && index != _settingsTab) _loadSettings();
    setState(() => _index = index);
  }

  Future<void> _openReceive() async {
    final settings = _settings;
    if (settings == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiveScreen(settings: settings),
      ),
    );
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = _settings;
    return Scaffold(
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _index,
              children: [
                HomeScreen(
                  receiving: _client.isActive,
                  onOpenReceive: _openReceive,
                  onShowGuide: () => _select(_connectTab),
                ),
                ConnectTab(
                  settings: settings,
                  onOpenReceive: _openReceive,
                  onGoHome: () => _select(_homeTab),
                ),
                const SettingsScreen(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wifi_tethering_outlined),
            selectedIcon: const Icon(Icons.wifi_tethering),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.devices_outlined),
            selectedIcon: const Icon(Icons.devices),
            label: l.navConnect,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.settingsTitle,
          ),
        ],
      ),
    );
  }
}
