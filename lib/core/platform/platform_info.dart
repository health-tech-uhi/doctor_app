import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// True for iOS and macOS — use for Cupertino-style UI without affecting Android/Web.
bool isApplePlatform(BuildContext context) {
  final p = Theme.of(context).platform;
  return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
}

/// Apple ecosystem only — avoids changing feel on Android/Web.
void hapticLightOnApple() {
  if (kIsWeb) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      HapticFeedback.lightImpact();
    default:
      break;
  }
}

void hapticSelectionOnApple() {
  if (kIsWeb) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      HapticFeedback.selectionClick();
    default:
      break;
  }
}
