import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';
import '../../data/models/insight_message.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final InsightMessage insight;

  @override
  Widget build(BuildContext context) {
    final border = insight.isCritical
        ? const Color(0xFFFF5252)
        : insight.isWarning
        ? DoctorTheme.accentAmber
        : DoctorTheme.accentCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: border.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insight.isCritical
                    ? Icons.warning_amber_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 18,
                color: border,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.title.isNotEmpty
                      ? insight.title
                      : insight.category,
                  style: TextStyle(
                    color: DoctorTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: border.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.severity,
                  style: TextStyle(
                    color: border,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (insight.detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              insight.detail,
              style: const TextStyle(
                color: DoctorTheme.secondaryText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
