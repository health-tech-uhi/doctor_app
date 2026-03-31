import 'package:flutter/material.dart';

import '../../platform/platform_info.dart';

/// Primary CTA: [FilledButton] everywhere (reliable theming) + light haptic on iOS/macOS only.
class AdaptivePrimaryButton extends StatelessWidget {
  const AdaptivePrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.minHeight = 48,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double minHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primary;
    final fg = foregroundColor ?? scheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed == null
            ? null
            : () {
                hapticLightOnApple();
                onPressed!();
              },
        child: child,
      ),
    );
  }
}
