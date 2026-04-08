import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_app/features/scribe/data/pcm_level_meter.dart';

void main() {
  group('pcm16leNormalizedRms', () {
    test('silence is near zero', () {
      final z = Uint8List.fromList(List<int>.filled(256, 0));
      expect(pcm16leNormalizedRms(z), lessThan(0.001));
    });

    test('detects non-zero signal', () {
      final b = ByteData(4);
      b.setInt16(0, 8000, Endian.little);
      b.setInt16(2, -8000, Endian.little);
      final u = b.buffer.asUint8List();
      expect(pcm16leNormalizedRms(u), greaterThan(0.2));
    });
  });

  group('pcm16leNormalizedLevel', () {
    test('peak from max int16', () {
      final b = ByteData(2);
      b.setInt16(0, 32767, Endian.little);
      expect(pcm16leNormalizedLevel(b.buffer.asUint8List()), closeTo(1.0, 0.02));
    });
  });
}
