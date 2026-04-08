import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_sound/flutter_sound.dart';

import 'pcm_level_meter.dart';

typedef OnPcmChunk = void Function(Uint8List data);
typedef OnPcmLevel = void Function(double normalized0to1);

/// Captures microphone PCM (16 kHz, mono, 16-bit) and forwards chunks to [onChunk].
class ScribePcmRecorder {
  ScribePcmRecorder({
    required this.onChunk,
    this.onLevel,
  });

  final OnPcmChunk onChunk;
  final OnPcmLevel? onLevel;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamController<Uint8List>? _pcmSink;
  StreamSubscription<Uint8List>? _sub;
  bool _open = false;

  static bool get supportedPlatform => !kIsWeb;

  Future<void> start() async {
    if (!supportedPlatform) return;

    await stop();

    _pcmSink = StreamController<Uint8List>();
    _sub = _pcmSink!.stream.listen((data) {
      onLevel?.call(pcm16leNormalizedRms(data));
      onChunk(data);
    });

    await _recorder.openRecorder();
    _open = true;

    await _recorder.startRecorder(
      codec: Codec.pcm16,
      toStream: _pcmSink!.sink,
      sampleRate: 16000,
      numChannels: 1,
      audioSource: AudioSource.microphone,
      bufferSize: 8192,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;

    if (_open) {
      try {
        await _recorder.stopRecorder();
      } catch (_) {}
      try {
        await _recorder.closeRecorder();
      } catch (_) {}
      _open = false;
    }

    if (_pcmSink != null && !_pcmSink!.isClosed) {
      await _pcmSink!.close();
    }
    _pcmSink = null;
  }
}
