import 'package:flutter/material.dart';

class PunchButton extends StatelessWidget {
  const PunchButton({
    super.key,
    required this.canPunch,
    required this.isDayFinalized,
    required this.onPressed,
    required this.pulseAnimation,
  });

  final bool canPunch;
  final bool isDayFinalized;
  final VoidCallback? onPressed;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final backgroundColor = canPunch
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);
    final foregroundColor =
        canPunch ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant;

    final button = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: canPunch
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.20),
                  blurRadius: 20,
                  spreadRadius: 1.5,
                ),
              ]
            : const [],
      ),
      child: SizedBox(
        width: 174,
        height: 174,
        child: Opacity(
          opacity: canPunch ? 1 : 0.85,
          child: FloatingActionButton(
            heroTag: 'punch_now_button',
            elevation: 0,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            onPressed: onPressed,
            shape: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                isDayFinalized ? 'Dia finalizado' : 'Bater Ponto Agora',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!canPunch) {
      return button;
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.014).animate(pulseAnimation),
      child: button,
    );
  }
}
