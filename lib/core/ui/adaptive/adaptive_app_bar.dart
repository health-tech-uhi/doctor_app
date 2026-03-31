import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../platform/platform_info.dart';
import '../../theme/doctor_theme.dart';

/// App bar: [CupertinoNavigationBar] on iOS/macOS, [AppBar] elsewhere (same titles/actions).
class AdaptiveAppBar {
  AdaptiveAppBar._();

  static PreferredSizeWidget forScreen(
    BuildContext context, {
    required String title,
    Color backgroundColor = DoctorTheme.surfaceElevated,
    List<Widget>? actions,
    Widget? leading,
  }) {
    if (isApplePlatform(context)) {
      return CupertinoNavigationBar(
        backgroundColor: backgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        middle: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: leading,
        trailing: actions != null && actions.isNotEmpty
            ? Row(mainAxisSize: MainAxisSize.min, children: actions)
            : null,
      );
    }
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(title),
      actions: actions,
      leading: leading,
    );
  }
}
