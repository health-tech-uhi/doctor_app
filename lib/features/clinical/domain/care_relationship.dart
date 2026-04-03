import 'package:flutter/foundation.dart';

/// Mirrors backend `clinical::CareRelationship`.
@immutable
class CareRelationship {
  const CareRelationship({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.firstConsultationDate,
    this.lastConsultationDate,
    this.relationshipStatus,
    this.lastConsentGrantId,
    required this.createdAt,
    required this.updatedAt,
    this.doctorName,
    this.patientName,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String? firstConsultationDate;
  final String? lastConsultationDate;
  final String? relationshipStatus;
  final String? lastConsentGrantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? doctorName;
  final String? patientName;

  factory CareRelationship.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(String key) {
      final v = json[key];
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(v as String).toLocal();
    }

    return CareRelationship(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      firstConsultationDate: json['first_consultation_date'] as String?,
      lastConsultationDate: json['last_consultation_date'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
      lastConsentGrantId: json['last_consent_grant_id'] as String?,
      createdAt: parseDt('created_at'),
      updatedAt: parseDt('updated_at'),
      doctorName: json['doctor_name'] as String?,
      patientName: json['patient_name'] as String?,
    );
  }

  String get displayPatientName =>
      patientName?.trim().isNotEmpty == true ? patientName!.trim() : 'Patient';
}
