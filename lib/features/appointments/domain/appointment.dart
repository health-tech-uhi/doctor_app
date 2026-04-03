import 'package:flutter/foundation.dart';

/// Mirrors backend `appointment::Appointment` (snake_case JSON).
@immutable
class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.clinicId,
    required this.requestedDatetime,
    this.confirmedDatetime,
    required this.status,
    this.appointmentMode,
    this.chiefComplaint,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.doctorName,
    this.patientName,
    this.clinicName,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String? clinicId;
  final DateTime requestedDatetime;
  final DateTime? confirmedDatetime;
  final String status;
  final String? appointmentMode;
  final String? chiefComplaint;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? doctorName;
  final String? patientName;
  final String? clinicName;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(String? key) {
      final v = json[key];
      if (v == null) return null;
      return DateTime.parse(v as String).toLocal();
    }

    return Appointment(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      clinicId: json['clinic_id'] as String?,
      requestedDatetime:
          parseDt('requested_datetime') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      confirmedDatetime: parseDt('confirmed_datetime'),
      status: (json['status'] as String?) ?? 'requested',
      appointmentMode: json['appointment_mode'] as String?,
      chiefComplaint: json['chief_complaint'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: parseDt('created_at') ?? DateTime.now(),
      updatedAt: parseDt('updated_at') ?? DateTime.now(),
      doctorName: json['doctor_name'] as String?,
      patientName: json['patient_name'] as String?,
      clinicName: json['clinic_name'] as String?,
    );
  }

  String get displayPatientName =>
      patientName?.trim().isNotEmpty == true ? patientName!.trim() : 'Patient';

  String get displayReason => chiefComplaint?.trim().isNotEmpty == true
      ? chiefComplaint!.trim()
      : 'Consultation';

  /// requested | accepted | rejected | completed | cancelled
  String get normalizedStatus => status.toLowerCase();
}
