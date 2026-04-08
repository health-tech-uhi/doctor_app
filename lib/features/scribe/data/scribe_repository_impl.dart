import 'package:dio/dio.dart';

import '../domain/scribe_repository.dart';
import 'models/summary_draft.dart';

/// Dio-backed [ScribeRepository].
class ScribeRepositoryImpl implements ScribeRepository {
  ScribeRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> submitApprovedSummary({
    required SummaryDraftModel draft,
    required String patientId,
    required String appointmentId,
  }) async {
    if (draft.summaryId.isEmpty) {
      throw StateError('summary_id is required');
    }

    await _dio.post<Map<String, dynamic>>(
      '/api/records/consultation-summary',
      data: _buildPayload(draft, patientId, appointmentId),
    );
  }

  Map<String, dynamic> _buildPayload(
    SummaryDraftModel d,
    String patientId,
    String appointmentId,
  ) {
    dynamic jsonish(dynamic v, dynamic emptyDefault) {
      if (v == null) return emptyDefault;
      return v;
    }

    return {
      if (d.sessionId != null && d.sessionId!.isNotEmpty)
        'session_id': d.sessionId,
      'summary_id': d.summaryId,
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'chief_complaint': d.chiefComplaint,
      'history_present': d.historyPresent,
      'review_of_systems': jsonish(d.reviewOfSystems, null),
      'physical_exam': jsonish(d.physicalExam, null),
      'assessment': d.assessment,
      'plan': d.plan,
      'diagnoses': jsonish(d.diagnoses, []),
      'medications': jsonish(d.medications, []),
      'allergies_flagged': jsonish(d.allergiesFlagged, []),
      'vitals': jsonish(d.vitals, {}),
      'follow_up': jsonish(d.followUp, null),
      'lab_orders': jsonish(d.labOrders, []),
      'insights_log': jsonish(d.insightsLog, []),
    };
  }
}
