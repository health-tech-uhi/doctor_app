import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/router/app_router.dart';
import 'core/theme/doctor_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: DoctorApp(),
    ),
  );
}

/// iOS-style overscroll; Android keeps clamping.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

class DoctorApp extends ConsumerWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Doctor App',
      scrollBehavior: const _AppScrollBehavior(),
      theme: DoctorTheme.dark(),
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        final p = Theme.of(context).platform;
        if (p == TargetPlatform.iOS || p == TargetPlatform.macOS) {
          return CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Brightness.dark,
              primaryColor: DoctorTheme.accent,
              barBackgroundColor: DoctorTheme.surfaceElevated,
              scaffoldBackgroundColor: DoctorTheme.scaffoldBackground,
            ),
            child: content,
          );
        }
        return content;
      },
      routerConfig: goRouter,
    );
  }
}
