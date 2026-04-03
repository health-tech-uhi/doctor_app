import 'package:flutter/material.dart';
import 'app_gradients.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(color: AppGradients.midnightBlue),

        // Aurora Orbs
        Positioned(
          top: -100,
          right: -50,
          child: _AuroraOrb(
            color: AppGradients.cyanMint.withOpacity(0.15),
            size: 400,
          ),
        ),
        Positioned(
          bottom: -50,
          left: -100,
          child: _AuroraOrb(
            color: AppGradients.deepLavender.withOpacity(0.15),
            size: 500,
          ),
        ),
        Positioned(
          top: 200,
          left: -150,
          child: _AuroraOrb(
            color: AppGradients.softAmber.withOpacity(0.1),
            size: 300,
          ),
        ),

        // The main content
        child,
      ],
    );
  }
}

class _AuroraOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AuroraOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    );
  }
}
