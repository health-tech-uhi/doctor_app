import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';
import '../../data/models/insight_message.dart';
import 'insight_card.dart';

class InsightsPanel extends StatelessWidget {
  const InsightsPanel({super.key, required this.insights});

  final List<InsightMessage> insights;

  @override
  Widget build(BuildContext context) {
    final sorted = [...insights]
      ..sort((a, b) {
        int rank(String s) {
          if (s == 'critical') return 0;
          if (s == 'warning') return 1;
          return 2;
        }

        return rank(a.severity).compareTo(rank(b.severity));
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: DoctorTheme.accentCyan,
            ),
            const SizedBox(width: 8),
            Text(
              'Live insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DoctorTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Insights from the AI will appear here as you speak.',
              style: TextStyle(color: DoctorTheme.textTertiary, fontSize: 13),
            ),
          )
        else
          ...sorted.map((e) => InsightCard(insight: e)),
      ],
    );
  }
}
