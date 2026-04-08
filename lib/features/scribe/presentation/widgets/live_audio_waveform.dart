import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';

/// Rolling buffer of normalized levels (0–1) for a live bar visualization.
class LiveWaveformController extends ChangeNotifier {
  LiveWaveformController({this.barCount = 40});

  final int barCount;
  final List<double> _levels = [];
  double _smooth = 0;

  bool _notifyScheduled = false;

  void _ensureInit() {
    if (_levels.length == barCount) return;
    _levels
      ..clear()
      ..addAll(List<double>.filled(barCount, 0));
  }

  /// Feed smoothed PCM-derived level (0–1).
  void pushLevel(double instantaneous) {
    _ensureInit();
    _smooth = 0.32 * instantaneous.clamp(0.0, 1.0) + 0.68 * _smooth;
    if (barCount <= 1) return;
    for (var i = 0; i < barCount - 1; i++) {
      _levels[i] = _levels[i + 1];
    }
    _levels[barCount - 1] = _smooth;
    _scheduleNotify();
  }

  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  void reset() {
    _ensureInit();
    for (var i = 0; i < barCount; i++) {
      _levels[i] = 0;
    }
    _smooth = 0;
    _notifyScheduled = false;
    notifyListeners();
  }

  List<double> get levels {
    _ensureInit();
    return List.unmodifiable(_levels);
  }
}

/// Paints bars only — no [ListenableBuilder], so PCM updates do not rebuild a
/// widget subtree (avoids iOS semantics churn when flutter_sound streams audio).
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.controller,
    required this.active,
    required this.barHeight,
  }) : super(repaint: controller);

  final LiveWaveformController controller;
  final bool active;
  final double barHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final levels = controller.levels;
    final n = levels.length;
    if (n <= 0 || size.width <= 0 || size.height <= 0) return;

    const gap = 2.0;
    final barW = (size.width - (n - 1) * gap) / n;
    var x = 0.0;
    for (var i = 0; i < n; i++) {
      final v = active ? levels[i] : 0.0;
      final h = 3.0 + v * (size.height - 3);
      final t = n > 1 ? i / (n - 1) : 0.0;
      final alpha = 0.25 + t * 0.55;
      final paint = Paint()
        ..color = DoctorTheme.accentCyan.withValues(
          alpha: active ? alpha * (0.4 + v * 0.6) : 0.12,
        )
        ..isAntiAlias = true;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
      x += barW;
      if (i < n - 1) x += gap;
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.active != active ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.controller != controller;
  }
}

/// Live level meter — [CustomPaint] + repaint [Listenable], not widget children.
class LiveAudioWaveform extends StatelessWidget {
  const LiveAudioWaveform({
    super.key,
    required this.controller,
    this.height = 44,
    this.active = true,
  });

  final LiveWaveformController controller;
  final double height;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _WaveformPainter(
              controller: controller,
              active: active,
              barHeight: height,
            ),
          ),
        ),
      ),
    );
  }
}
