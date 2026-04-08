import 'dart:math' as math;
import 'dart:typed_data';

/// Peak-based normalized level (0–1) for 16-bit little-endian mono PCM.
double pcm16leNormalizedLevel(Uint8List bytes) {
  if (bytes.length < 2) return 0;
  var peak = 0;
  for (var i = 0; i < bytes.length - 1; i += 2) {
    var s = bytes[i] | (bytes[i + 1] << 8);
    if (s > 32767) s -= 65536;
    final a = s.abs();
    if (a > peak) peak = a;
  }
  return (peak / 32768.0).clamp(0.0, 1.0);
}

/// RMS-based level (0–1), slightly smoother than raw peak.
double pcm16leNormalizedRms(Uint8List bytes) {
  if (bytes.length < 2) return 0;
  final n = bytes.length >> 1;
  if (n == 0) return 0;
  var sum = 0.0;
  for (var i = 0; i < bytes.length - 1; i += 2) {
    var s = bytes[i] | (bytes[i + 1] << 8);
    if (s > 32767) s -= 65536;
    final d = s.toDouble();
    sum += d * d;
  }
  final rms = math.sqrt(sum / n);
  return (rms / 12000.0).clamp(0.0, 1.0);
}
