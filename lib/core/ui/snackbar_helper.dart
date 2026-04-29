import 'package:flutter/material.dart';

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    final theme = Theme.of(context);
    _show(
      context: context,
      message: message,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      duration: const Duration(seconds: 2),
    );
  }

  static void showError(BuildContext context, String message) {
    final theme = Theme.of(context);
    _show(
      context: context,
      message: message,
      backgroundColor: theme.colorScheme.errorContainer,
      textStyle: TextStyle(
        color: theme.colorScheme.onErrorContainer,
        fontSize: 14,
      ),
      duration: const Duration(seconds: 3),
    );
  }

  static void showWarning(BuildContext context, String message) {
    final theme = Theme.of(context);
    _show(
      context: context,
      message: message,
      backgroundColor: theme.colorScheme.tertiaryContainer,
      textStyle: TextStyle(
        color: theme.colorScheme.onTertiaryContainer,
        fontSize: 14,
      ),
      duration: const Duration(seconds: 3),
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required TextStyle? textStyle,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: textStyle),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        duration: duration,
      ),
    );
  }
}
