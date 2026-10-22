import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/share_settings.dart';
import '../widgets/client_panel.dart';
import '../widgets/share_panel.dart';
import '../services/share_channel.dart';
import 'settings_screen.dart';

enum AppMode { share, connect }

/// App bar, the Share / Connect mode switch, and the panel for the selected mode.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ShareSettingsData? _settings;
  AppMode _mode = AppMode.share;

  /// True while the current mode's panel is starting or running.
  bool _panelActive = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ShareChannel.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _mode = settings.mode == AppMode.connect.name
          ? AppMode.connect
          : AppMode.share;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    _loadSettings();
  }

  void _setMode(AppMode mode) {
    setState(() => _mode = mode);
    ShareChannel.setMode(mode.name);
  }

  void _onPanelActiveChanged(bool active) {
    if (active != _panelActive) setState(() => _panelActive = active);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l.settingsTitle,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<AppMode>(
              segments: [
                ButtonSegment(
                  value: AppMode.share,
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(l.modeShare),
                ),
                ButtonSegment(
                  value: AppMode.connect,
                  icon: const Icon(Icons.vpn_lock),
                  label: Text(l.modeConnect),
                ),
              ],
              selected: {_mode},
              // Don't let the user switch modes while sharing or connected.
              onSelectionChanged: _panelActive
                  ? null
                  : (selection) => _setMode(selection.first),
            ),
            const SizedBox(height: 24),
            if (settings == null)
              const Center(child: CircularProgressIndicator())
            else if (_mode == AppMode.connect)
              ClientPanel(
                initialPort: settings.clientPort,
                onActiveChanged: _onPanelActiveChanged,
              )
            else
              SharePanel(
                settings: settings,
                onActiveChanged: _onPanelActiveChanged,
              ),
          ],
        ),
      ),
    );
  }
}
