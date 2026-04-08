import 'package:flutter/foundation.dart';

@immutable
class TranscriptMessage {
  const TranscriptMessage({
    required this.speaker,
    required this.text,
    required this.original,
    required this.language,
    required this.timestampMs,
  });

  final String speaker;
  final String text;
  final String original;
  final String language;
  final int timestampMs;

  factory TranscriptMessage.fromJson(Map<String, dynamic> json) {
    return TranscriptMessage(
      speaker: json['speaker'] as String? ?? 'unknown',
      text: json['text'] as String? ?? '',
      original: json['original'] as String? ?? '',
      language: json['language'] as String? ?? '',
      timestampMs: (json['timestamp_ms'] as num?)?.toInt() ?? 0,
    );
  }
}
