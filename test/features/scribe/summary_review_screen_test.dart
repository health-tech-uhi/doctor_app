import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_app/features/scribe/data/models/summary_draft.dart';
import 'package:doctor_app/features/scribe/domain/scribe_repository.dart';
import 'package:doctor_app/features/scribe/presentation/summary_review_screen.dart';
import 'package:doctor_app/features/scribe/providers/scribe_providers.dart';

class _FakeScribeRepository implements ScribeRepository {
  int submitCount = 0;
  SummaryDraftModel? lastDraft;

  @override
  Future<void> submitApprovedSummary({
    required SummaryDraftModel draft,
    required String patientId,
    required String appointmentId,
  }) async {
    submitCount++;
    lastDraft = draft;
  }
}

void main() {
  testWidgets('Approve & send calls ScribeRepository after confirm', (
    tester,
  ) async {
    final fake = _FakeScribeRepository();
    const sid = '018f1234-5678-7abc-8def-123456789abc';
    const pid = '028f1234-5678-7abc-8def-123456789abc';
    const aid = '038f1234-5678-7abc-8def-123456789abc';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scribeRepositoryProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          home: SummaryReviewScreen(
            args: ScribeSummaryReviewArgs(
              draft: SummaryDraftModel(
                summaryId: sid,
                sessionId: sid,
                chiefComplaint: 'Cough',
                diagnoses: [
                  {'code': 'J00', 'name': 'Common cold'},
                ],
                medications: [
                  {
                    'name': 'Honey lemon',
                    'dose': 'PRN',
                    'frequency': '',
                    'duration': '',
                  },
                ],
              ),
              patientId: pid,
              appointmentId: aid,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('scribe_summary_approve')),
      find.byKey(const Key('scribe_review_scroll')),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scribe_summary_approve')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(fake.submitCount, 1);
    expect(fake.lastDraft, isNotNull);
    expect(fake.lastDraft!.summaryId, sid);
    expect(fake.lastDraft!.diagnoses, isA<List>());
    expect(fake.lastDraft!.medications, isA<List>());
  });
}
