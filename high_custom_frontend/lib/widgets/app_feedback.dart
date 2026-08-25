import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

enum AppFeedbackType { success, warning, error }

class AppFeedback {
  static bool looksLikeWarning(String message) {
    final value = message.toLowerCase();
    return value.contains('already') ||
        value.contains('exists') ||
        value.contains('duplicate') ||
        value.contains('found');
  }

  static bool looksLikeError(String message) {
    final value = message.toLowerCase();
    return value.contains('error') ||
        value.contains('failed') ||
        value.contains('invalid') ||
        value.contains('required') ||
        value.contains('unable') ||
        value.contains('could not');
  }

  static void show(BuildContext context, String message,
      {bool isError = false, AppFeedbackType? type}) {
    final resolvedType = type ??
        (isError
            ? (looksLikeWarning(message)
                ? AppFeedbackType.warning
                : AppFeedbackType.error)
            : (looksLikeWarning(message)
                ? AppFeedbackType.warning
                : (looksLikeError(message)
                    ? AppFeedbackType.error
                    : AppFeedbackType.success)));
    final Color background;
    final Color foreground;
    final IconData icon;

    switch (resolvedType) {
      case AppFeedbackType.success:
        background = AppTheme.success;
        foreground = Colors.white;
        icon = Icons.check_circle_outline;
      case AppFeedbackType.warning:
        background = AppTheme.warning;
        foreground = const Color(0xFF17120A);
        icon = Icons.warning_amber_rounded;
      case AppFeedbackType.error:
        background = const Color(0xFF7F1D1D);
        foreground = Colors.white;
        icon = Icons.error_outline;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: TextStyle(color: foreground))),
            ],
          ),
        ),
      );
  }
}
