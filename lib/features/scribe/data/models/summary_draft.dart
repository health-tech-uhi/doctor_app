import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Draft SOAP + structured fields from the relay (`summary_draft` WebSocket message).
@immutable
class SummaryDraftModel {
  const SummaryDraftModel({
    required this.summaryId,
    this.sessionId,
    this.chiefComplaint,
    this.historyPresent,
    this.reviewOfSystems,
    this.physicalExam,
    this.assessment,
    this.plan,
    this.diagnoses,
    this.medications,
    this.allergiesFlagged,
    this.vitals,
    this.followUp,
    this.labOrders,
    this.insightsLog,
  });

  final String summaryId;
  final String? sessionId;
  final String? chiefComplaint;
  final String? historyPresent;
  final dynamic reviewOfSystems;
  final dynamic physicalExam;
  final String? assessment;
  final String? plan;
  final dynamic diagnoses;
  final dynamic medications;
  final dynamic allergiesFlagged;
  final dynamic vitals;
  final dynamic followUp;
  final dynamic labOrders;
  final dynamic insightsLog;

  factory SummaryDraftModel.fromWsJson(Map<String, dynamic> json) {
    dynamic decodeField(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        final t = v.trim();
        if (t.isEmpty) return null;
        try {
          return jsonDecode(t);
        } catch (_) {
          return v;
        }
      }
      return v;
    }

    final allergies =
        json['allergies_flagged'] ?? json['allergies'] ?? json['allergies_json'];

    return SummaryDraftModel(
      summaryId: json['summary_id'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      chiefComplaint: json['chief_complaint'] as String?,
      historyPresent: json['history_present'] as String?,
      reviewOfSystems: decodeField(json['review_of_systems']),
      physicalExam: decodeField(json['physical_exam']),
      assessment: json['assessment'] as String?,
      plan: json['plan'] as String?,
      diagnoses: decodeField(json['diagnoses'] ?? json['diagnoses_json']),
      medications: decodeField(json['medications'] ?? json['medications_json']),
      allergiesFlagged: decodeField(allergies),
      vitals: decodeField(json['vitals'] ?? json['vitals_json']),
      followUp: decodeField(json['follow_up'] ?? json['follow_up_json']),
      labOrders: decodeField(json['lab_orders'] ?? json['lab_orders_json']),
      insightsLog: decodeField(json['insights_log']),
    );
  }

  SummaryDraftModel copyWith({
    String? summaryId,
    String? sessionId,
    String? chiefComplaint,
    String? historyPresent,
    dynamic reviewOfSystems,
    dynamic physicalExam,
    String? assessment,
    String? plan,
    dynamic diagnoses,
    dynamic medications,
    dynamic allergiesFlagged,
    dynamic vitals,
    dynamic followUp,
    dynamic labOrders,
    dynamic insightsLog,
  }) {
    return SummaryDraftModel(
      summaryId: summaryId ?? this.summaryId,
      sessionId: sessionId ?? this.sessionId,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      historyPresent: historyPresent ?? this.historyPresent,
      reviewOfSystems: reviewOfSystems ?? this.reviewOfSystems,
      physicalExam: physicalExam ?? this.physicalExam,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      allergiesFlagged: allergiesFlagged ?? this.allergiesFlagged,
      vitals: vitals ?? this.vitals,
      followUp: followUp ?? this.followUp,
      labOrders: labOrders ?? this.labOrders,
      insightsLog: insightsLog ?? this.insightsLog,
    );
  }
}
