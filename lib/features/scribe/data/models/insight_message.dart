import 'package:flutter/foundation.dart';

@immutable
class InsightMessage {
  const InsightMessage({
    required this.category,
    required this.severity,
    required this.title,
    required this.detail,
    required this.sourceText,
  });

  final String category;
  final String severity;
  final String title;
  final String detail;
  final String sourceText;

  factory InsightMessage.fromJson(Map<String, dynamic> json) {
    return InsightMessage(
      category: json['category'] as String? ?? 'info',
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      sourceText: json['source_text'] as String? ?? '',
    );
  }

  bool get isCritical => severity == 'critical';
  bool get isWarning => severity == 'warning';
}
