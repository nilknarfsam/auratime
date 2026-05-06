import 'package:flutter/material.dart';

class PunchButton extends StatelessWidget {
  const PunchButton({
    super.key,
    required this.canPunch,
    required this.isDayFinalized,
    required this.onPressed,
  });

  final bool canPunch;
  final bool isDayFinalized;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isDayFinalized ? 'Dia finalizado' : 'Bater ponto agora';
    final radius = BorderRadius.circular(14);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: canPunch
                    ? theme.colorScheme.primary.withValues(alpha: 0.45)
                    : theme.colorScheme.outline.withValues(alpha: 0.22),
              ),
              color: canPunch
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              boxShadow: canPunch
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDayFinalized ? Icons.check_circle_outline_rounded : Icons.touch_app_rounded,
                    size: 22,
                    color: canPunch
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: canPunch
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
