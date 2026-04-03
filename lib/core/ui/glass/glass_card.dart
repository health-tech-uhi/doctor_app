import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/doctor_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.opacity = 0.08,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20);
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: (color ?? DoctorTheme.glassSurface).withValues(alpha: opacity),
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: (borderColor ?? DoctorTheme.glassStroke),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
