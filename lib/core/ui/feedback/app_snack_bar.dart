import 'package:flutter/material.dart';

/// Consistent, non-jarring feedback: floating, rounded, theme-aligned.
abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }
}
