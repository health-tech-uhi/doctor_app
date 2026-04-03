import 'package:flutter/foundation.dart';

/// Mirrors the backend `identity.doctors` record returned by GET /api/doctors/profile.
/// Used throughout the app to display and gate features based on verification status.
@immutable
class DoctorProfile {
  final String id;
  final String userId;
  final String fullName;
  final String specialization;
  final String? qualification;
  final int? experienceYears;
  final String? bio;
  final List<String>? languagesSpoken;
  final String? licenseNumber;
  final String? licenseIssuingAuthority;

  /// Raw verification status string from backend: 'pending' | 'verified' | 'rejected'
  final String? verificationStatus;
  final double? consultationFeeInr;
  final bool? isAcceptingPatients;
  final String? degree;
  final String? degreeInstitution;
  final int? degreeYear;
  final int? registrationYear;
  final String? stateMedicalCouncil;
  final String? aadhaarLastFour;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.specialization,
    this.qualification,
    this.experienceYears,
    this.bio,
    this.languagesSpoken,
    this.licenseNumber,
    this.licenseIssuingAuthority,
    this.verificationStatus,
    this.consultationFeeInr,
    this.isAcceptingPatients,
    this.degree,
    this.degreeInstitution,
    this.degreeYear,
    this.registrationYear,
    this.stateMedicalCouncil,
    this.aadhaarLastFour,
    required this.createdAt,
    required this.updatedAt,
  });

  static double? _parseConsultationFee(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      qualification: json['qualification'] as String?,
      experienceYears: json['experience_years'] as int?,
      bio: json['bio'] as String?,
      languagesSpoken: (json['languages_spoken'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      licenseNumber: json['license_number'] as String?,
      licenseIssuingAuthority: json['license_issuing_authority'] as String?,
      verificationStatus: json['verification_status'] as String?,
      consultationFeeInr: _parseConsultationFee(json['consultation_fee_inr']),
      isAcceptingPatients: json['is_accepting_patients'] as bool?,
      degree: json['degree'] as String?,
      degreeInstitution: json['degree_institution'] as String?,
      degreeYear: json['degree_year'] as int?,
      registrationYear: json['registration_year'] as int?,
      stateMedicalCouncil: json['state_medical_council'] as String?,
      aadhaarLastFour: json['aadhaar_last_four'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// True when the backend has marked this doctor as fully KYC-approved.
  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
}
