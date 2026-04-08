import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';
import '../../data/models/transcript_message.dart';

/// Live transcript list. Uses a single [CustomScrollView] inside the flex region
/// (no ListView inside Column+Expanded) to avoid iOS semantics / layout assertions.
class LiveTranscriptPanel extends StatelessWidget {
  const LiveTranscriptPanel({
    super.key,
    required this.lines,
    required this.scrollController,
  });

  final List<TranscriptMessage> lines;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: DoctorTheme.textPrimary,
          fontWeight: FontWeight.w800,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.subtitles_outlined,
              size: 18,
              color: DoctorTheme.accentLavender,
            ),
            const SizedBox(width: 8),
            Text('Live transcript', style: titleStyle),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DoctorTheme.glassSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DoctorTheme.glassStroke),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (lines.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'Transcript will stream here…',
                          style: TextStyle(
                            color: DoctorTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final m = lines[i];
                            final isDoctor =
                                m.speaker.toLowerCase().contains('doctor');
                            final label = isDoctor ? 'Doctor' : 'Patient';
                            final color = isDoctor
                                ? DoctorTheme.accentCyan
                                : DoctorTheme.accentLavender;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: DoctorTheme.secondaryText,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$label: ',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(
                                      text: m.text.isNotEmpty
                                          ? m.text
                                          : m.original,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: lines.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
