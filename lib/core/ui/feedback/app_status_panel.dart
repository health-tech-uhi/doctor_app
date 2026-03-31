import 'package:flutter/material.dart';

/// Empty / error / success panel with icon, title, optional body copy, and optional CTA.
/// Keeps messaging consistent and screen-reader friendly.
class AppStatusPanel extends StatelessWidget {
  const AppStatusPanel({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.iconColor,
    this.iconSize = 52,
    this.primaryAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Color? iconColor;
  final double iconSize;
  final Widget? primaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ic = iconColor ?? scheme.primary;
    final secondary = scheme.onSurface.withValues(alpha: 0.72);

    final content = Semantics(
      container: true,
      label: message != null ? '$title. $message' : title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: ic),
          SizedBox(height: compact ? 10 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (message != null) ...[
            SizedBox(height: compact ? 6 : 10),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondary,
                    height: 1.45,
                  ),
            ),
          ],
          if (primaryAction != null) ...[
            SizedBox(height: compact ? 16 : 22),
            primaryAction!,
          ],
        ],
      ),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
