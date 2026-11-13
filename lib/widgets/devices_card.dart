import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/share_status.dart';
import '../services/share_channel.dart';
import '../utils/format.dart';
import 'settings_dialogs.dart';

enum _DeviceAction { rename, disconnect, allow }

/// Phones using the shared internet this session, each with its data and a menu
/// to rename it or cut it off.
class DevicesCard extends StatelessWidget {
  const DevicesCard({super.key, required this.devices});

  final List<ConnectedDevice> devices;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.devices,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.devicesTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (devices.isNotEmpty)
                    Text(
                      '${devices.length}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l.devicesEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final device in devices) _DeviceTile(device: device),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});

  final ConnectedDevice device;

  Future<void> _onAction(BuildContext context, _DeviceAction action) async {
    switch (action) {
      case _DeviceAction.rename:
        await _rename(context);
      case _DeviceAction.disconnect:
        await _confirmDisconnect(context);
      case _DeviceAction.allow:
        await ShareChannel.setDeviceBlocked(device.address, false);
    }
  }

  Future<void> _rename(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final value = await showTextSettingDialog(
      context,
      title: l.deviceNickname,
      initialValue: device.displayName ?? '',
      maxLength: 40,
      ltr: false,
      helper: (_) => l.deviceNicknameHelper,
      validator: (_) => null,
    );
    if (value != null) await ShareChannel.renameDevice(device.address, value);
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.displayName ?? device.address),
        content: Text(l.deviceDisconnectConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.deviceDisconnect),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ShareChannel.setDeviceBlocked(device.address, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;

    // While data flows, the live download speed; otherwise just the totals.
    final traffic = [
      '↓ ${formatBytes(device.bytesDown)}',
      '↑ ${formatBytes(device.bytesUp)}',
      if (device.active && device.speedDown > 0) formatSpeed(device.speedDown),
    ].join('  ·  ');

    return ListTile(
      leading: _DeviceAvatar(device: device),
      title: Text(
        device.displayName ?? l.deviceUnnamed,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: device.blocked ? TextStyle(color: muted) : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(device.address, textDirection: TextDirection.ltr),
          if (device.blocked)
            Text(l.deviceBlocked, style: TextStyle(color: scheme.error))
          else
            Text(
              traffic,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<_DeviceAction>(
        onSelected: (action) => _onAction(context, action),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _DeviceAction.rename,
            child: ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.deviceRename),
            ),
          ),
          if (device.blocked)
            PopupMenuItem(
              value: _DeviceAction.allow,
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(l.deviceAllow),
              ),
            )
          else
            PopupMenuItem(
              value: _DeviceAction.disconnect,
              child: ListTile(
                leading: Icon(Icons.block, color: scheme.error),
                title: Text(
                  l.deviceDisconnect,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Phone icon with a dot while it has open connections; a block icon when cut off.
class _DeviceAvatar extends StatelessWidget {
  const _DeviceAvatar({required this.device});

  final ConnectedDevice device;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (device.blocked) {
      return CircleAvatar(
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        child: const Icon(Icons.block, size: 20),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: const Icon(Icons.smartphone, size: 20),
        ),
        if (device.active)
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surfaceContainerLow, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
