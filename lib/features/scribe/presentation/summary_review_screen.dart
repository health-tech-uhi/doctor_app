import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../core/theme/doctor_theme.dart';
import '../../../core/ui/feedback/app_snack_bar.dart';
import '../data/models/summary_draft.dart';
import '../domain/clinical_summary_lists.dart';
import '../providers/scribe_providers.dart';
import 'summary_edit_widgets/diagnosis_list_editor.dart';
import 'summary_edit_widgets/medication_list_editor.dart';
import 'summary_edit_widgets/soap_section_editor.dart';

class ScribeSummaryReviewArgs {
  ScribeSummaryReviewArgs({
    required this.draft,
    required this.patientId,
    required this.appointmentId,
    this.sessionId,
  });

  final SummaryDraftModel draft;
  final String patientId;
  final String appointmentId;
  final String? sessionId;
}

/// Doctor edits the AI draft and approves → immutable record + patient notification.
class SummaryReviewScreen extends ConsumerStatefulWidget {
  const SummaryReviewScreen({super.key, required this.args});

  final ScribeSummaryReviewArgs args;

  @override
  ConsumerState<SummaryReviewScreen> createState() =>
      _SummaryReviewScreenState();
}

class _SummaryReviewScreenState extends ConsumerState<SummaryReviewScreen> {
  late final TextEditingController _chief;
  late final TextEditingController _hpi;
  late final TextEditingController _assessment;
  late final TextEditingController _plan;
  late final TextEditingController _ros;
  late final TextEditingController _pe;
  late final TextEditingController _allergies;
  late final TextEditingController _vitals;
  late final TextEditingController _followUp;
  late final TextEditingController _labs;
  late final TextEditingController _insights;

  late List<Map<String, dynamic>> _diagnoses;
  late List<Map<String, dynamic>> _medications;

  bool _busy = false;
  String? _sessionIdBuf;

  @override
  void initState() {
    super.initState();
    final d = widget.args.draft;
    _sessionIdBuf = (d.sessionId != null && d.sessionId!.isNotEmpty)
        ? d.sessionId
        : widget.args.sessionId;
    _chief = TextEditingController(text: d.chiefComplaint ?? '');
    _hpi = TextEditingController(text: d.historyPresent ?? '');
    _assessment = TextEditingController(text: d.assessment ?? '');
    _plan = TextEditingController(text: d.plan ?? '');
    _ros = TextEditingController(text: _stringify(d.reviewOfSystems));
    _pe = TextEditingController(text: _stringify(d.physicalExam));
    _allergies = TextEditingController(text: _stringify(d.allergiesFlagged));
    _vitals = TextEditingController(text: _stringify(d.vitals));
    _followUp = TextEditingController(text: _stringify(d.followUp));
    _labs = TextEditingController(text: _stringify(d.labOrders));
    _insights = TextEditingController(text: _stringify(d.insightsLog));
    _diagnoses = parseDiagnosisList(d.diagnoses);
    _medications = parseMedicationList(d.medications);
  }

  @override
  void dispose() {
    _chief.dispose();
    _hpi.dispose();
    _assessment.dispose();
    _plan.dispose();
    _ros.dispose();
    _pe.dispose();
    _allergies.dispose();
    _vitals.dispose();
    _followUp.dispose();
    _labs.dispose();
    _insights.dispose();
    super.dispose();
  }

  String _stringify(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    try {
      return const JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return v.toString();
    }
  }

  dynamic _tryJson(String raw, dynamic empty) {
    final t = raw.trim();
    if (t.isEmpty) return empty;
    try {
      return jsonDecode(t);
    } catch (_) {
      throw FormatException('Invalid JSON');
    }
  }

  Future<void> _approve() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve & send?'),
        content: const Text(
          'This creates a permanent record and notifies the patient.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      dynamic ros;
      dynamic pe;
      dynamic allergies;
      dynamic vitals;
      dynamic fu;
      dynamic labs;
      dynamic insights;
      try {
        ros = _tryJson(_ros.text, null);
        pe = _tryJson(_pe.text, null);
        allergies = _tryJson(_allergies.text, []);
        vitals = _tryJson(_vitals.text, {});
        fu = _tryJson(_followUp.text, null);
        labs = _tryJson(_labs.text, []);
        insights = _tryJson(_insights.text, []);
      } on FormatException catch (e) {
        if (mounted) {
          AppSnackBar.show(context, e.message, isError: true);
        }
        return;
      }

      final dx = filterDiagnosisEntries(_diagnoses);
      final meds = filterMedicationEntries(_medications);

      final merged = widget.args.draft.copyWith(
        sessionId: _sessionIdBuf ?? widget.args.draft.sessionId,
        chiefComplaint: _chief.text.trim().isEmpty ? null : _chief.text.trim(),
        historyPresent: _hpi.text.trim().isEmpty ? null : _hpi.text.trim(),
        assessment: _assessment.text.trim().isEmpty
            ? null
            : _assessment.text.trim(),
        plan: _plan.text.trim().isEmpty ? null : _plan.text.trim(),
        reviewOfSystems: ros,
        physicalExam: pe,
        diagnoses: dx,
        medications: meds,
        allergiesFlagged: allergies,
        vitals: vitals,
        followUp: fu,
        labOrders: labs,
        insightsLog: insights,
      );

      await ref.read(scribeRepositoryProvider).submitApprovedSummary(
            draft: merged,
            patientId: widget.args.patientId,
            appointmentId: widget.args.appointmentId,
          );

      if (!mounted) return;
      AppSnackBar.show(context, 'Summary approved. Patient notified.');
      context.go('/schedule');
    } on DioException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, userFacingErrorMessage(e), isError: true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, userFacingErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Consultation summary',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('scribe_review_scroll'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              'Review and edit before approval',
              style: TextStyle(
                color: DoctorTheme.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SoapSectionEditor(
              chiefComplaint: _chief,
              historyPresent: _hpi,
              assessment: _assessment,
              plan: _plan,
            ),
            const SizedBox(height: 8),
            DiagnosisListEditor(
              initial: _diagnoses,
              onChanged: (v) => setState(() => _diagnoses = v),
            ),
            const SizedBox(height: 8),
            MedicationListEditor(
              initial: _medications,
              onChanged: (v) => setState(() => _medications = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Structured data (JSON)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DoctorTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _jsonField('Review of systems', _ros, 6),
            _jsonField('Physical exam', _pe, 6),
            _jsonField('Allergies flagged', _allergies, 6),
            _jsonField('Vitals', _vitals, 6),
            _jsonField('Follow-up', _followUp, 4),
            _jsonField('Lab orders', _labs, 6),
            _jsonField('Insights log', _insights, 8),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => context.pop(),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    key: const Key('scribe_summary_approve'),
                    onPressed: _busy ? null : _approve,
                    style: FilledButton.styleFrom(
                      backgroundColor: DoctorTheme.accentCyan,
                      foregroundColor: Colors.black87,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black87,
                            ),
                          )
                        : const Text('Approve & send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _jsonField(String label, TextEditingController c, int maxLines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DoctorTheme.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            maxLines: maxLines,
            style: const TextStyle(
              color: DoctorTheme.textPrimary,
              fontSize: 14,
              height: 1.35,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: DoctorTheme.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DoctorTheme.glassStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DoctorTheme.glassStroke),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
