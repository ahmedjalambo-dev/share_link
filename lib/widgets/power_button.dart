import 'package:flutter/material.dart';

enum PowerState { idle, working, active, error }

/// Big round Start/Stop (or Connect/Disconnect) button.
class PowerButton extends StatelessWidget {
  const PowerButton({
    super.key,
    required this.state,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final PowerState state;
  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (state) {
      PowerState.active => (scheme.primary, scheme.onPrimary),
      PowerState.working => (scheme.tertiary, scheme.onTertiary),
      PowerState.error => (scheme.errorContainer, scheme.onErrorContainer),
      PowerState.idle => (scheme.surfaceContainerHighest, scheme.onSurface),
    };

    return SizedBox.square(
      dimension: 180,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state == PowerState.working)
                SizedBox.square(
                  dimension: 56,
                  child: CircularProgressIndicator(color: foreground),
                )
              else
                Icon(Icons.power_settings_new, size: 64, color: foreground),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status pill under the power button.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.state, required this.label});

  final PowerState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (state) {
      PowerState.idle => scheme.outline,
      PowerState.working => scheme.tertiary,
      PowerState.active => scheme.primary,
      PowerState.error => scheme.error,
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(label),
    );
  }
}
