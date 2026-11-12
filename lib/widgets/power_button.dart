import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PowerState { idle, working, active, error }

/// Big round Start/Stop (or Connect/Disconnect) button.
/// While active, soft rings pulse out from it (skipped when the system turns animations off).
class PowerButton extends StatefulWidget {
  const PowerButton({
    super.key,
    required this.state,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.size = 168,
  });

  final PowerState state;
  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final double size;

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton>
    with SingleTickerProviderStateMixin {
  /// How far the rings grow past the button, as a fraction of its size.
  static const _ringGrowth = 0.3;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(PowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final pulsing =
        widget.state == PowerState.active &&
        !MediaQuery.disableAnimationsOf(context);
    if (pulsing) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (widget.state) {
      PowerState.active => (scheme.primary, scheme.onPrimary),
      PowerState.working => (scheme.tertiary, scheme.onTertiary),
      PowerState.error => (scheme.errorContainer, scheme.onErrorContainer),
      PowerState.idle => (scheme.surfaceContainerHighest, scheme.onSurface),
    };
    final size = widget.size;

    return SizedBox.square(
      dimension: size * (1 + _ringGrowth),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                if (_pulse.isAnimating)
                  for (final offset in const [0.0, 0.5])
                    _ring((_pulse.value + offset) % 1, scheme.primary),
              ],
            ),
          ),
          SizedBox.square(
            dimension: size,
            child: Material(
              color: background,
              shape: const CircleBorder(),
              elevation: widget.state == PowerState.active ? 6 : 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.busy ? null : _tap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.state == PowerState.working)
                      SizedBox.square(
                        dimension: size * 0.3,
                        child: CircularProgressIndicator(color: foreground),
                      )
                    else
                      Icon(
                        Icons.power_settings_new,
                        size: size * 0.36,
                        color: foreground,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One expanding, fading ring at [progress] (0 → 1) of its cycle.
  Widget _ring(double progress, Color color) {
    final dimension = widget.size * (1 + _ringGrowth * progress);
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.25 * (1 - progress)),
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
