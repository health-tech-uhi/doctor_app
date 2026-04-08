import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';

/// Recording badge + elapsed time. No driving animation (avoids semantics churn
/// with the rest of the scribe UI on iOS).
class RecordingIndicator extends StatelessWidget {
  const RecordingIndicator({
    super.key,
    required this.elapsed,
    this.compact = false,
  });

  final Duration elapsed;
  final bool compact;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fs = compact ? 13.0 : 15.0;
    final label = 'Recording  ${_fmt(elapsed)}';
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_manual_record_rounded,
            size: compact ? 12 : 14,
            color: const Color(0xFFFF5252),
          ),
          SizedBox(width: compact ? 8 : 10),
          ExcludeSemantics(
            child: Text(
              label,
              style: TextStyle(
                color: DoctorTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: fs,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
