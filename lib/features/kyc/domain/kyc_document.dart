import 'package:flutter/foundation.dart';

/// Mirrors the `KycDocument` DTO returned by GET /api/doctors/kyc/status.
@immutable
class KycDocument {
  final String id;
  final String documentType;
  final String fileName;
  final String? mimeType;
  final String garageObjectUuid;

  /// Raw status: 'pending' | 'approved' | 'rejected'
  final String status;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const KycDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    this.mimeType,
    required this.garageObjectUuid,
    required this.status,
    this.rejectionReason,
    this.verifiedAt,
    required this.createdAt,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      id: json['id'] as String,
      documentType: json['document_type'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String?,
      garageObjectUuid: json['garage_object_uuid'] as String,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Holds the full KYC verification status response from GET /api/doctors/kyc/status.
@immutable
class KycStatus {
  final String verificationStatus;
  final List<KycDocument> documents;
  final Map<String, dynamic>? nmcVerificationResult;

  const KycStatus({
    required this.verificationStatus,
    required this.documents,
    this.nmcVerificationResult,
  });

  factory KycStatus.fromJson(Map<String, dynamic> json) {
    final docs =
        (json['documents'] as List<dynamic>?)
            ?.map((d) => KycDocument.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];
    return KycStatus(
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      documents: docs,
      nmcVerificationResult:
          json['nmc_verification_result'] as Map<String, dynamic>?,
    );
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get isRejected => verificationStatus == 'rejected';
}
