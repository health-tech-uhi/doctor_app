import 'package:flutter/material.dart';

class AppGradients {
  static const Color midnightBlue = Color(0xFF0B1426);
  static const Color charcoalGreen = Color(0xFF1A1F2B);
  
  // Aurora Accent Colors
  static const Color cyanMint = Color(0xFF4ACFD9);
  static const Color deepLavender = Color(0xFF9181F4);
  static const Color softAmber = Color(0xFFFFB347);
  static const Color medicalMint = Color(0xFFB9FBC0);

  static const LinearGradient auroraPrimary = LinearGradient(
    colors: [cyanMint, deepLavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraSecondary = LinearGradient(
    colors: [deepLavender, Color(0xFFBE93C5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorder = LinearGradient(
    colors: [
      Colors.white24,
      Colors.white10,
      Colors.white12,
      Colors.white24,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceOverlay = LinearGradient(
    colors: [
      Colors.white10,
      Colors.transparent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cyanMintGradient = LinearGradient(
    colors: [cyanMint, medicalMint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
