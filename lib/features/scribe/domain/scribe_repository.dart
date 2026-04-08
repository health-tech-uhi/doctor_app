import '../data/models/summary_draft.dart';

/// Persists an approved consultation summary to health-platform.
abstract class ScribeRepository {
  Future<void> submitApprovedSummary({
    required SummaryDraftModel draft,
    required String patientId,
    required String appointmentId,
  });
}
