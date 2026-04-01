import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/doctor_profile.dart';

class DoctorProfileNotFoundException implements Exception {
  const DoctorProfileNotFoundException();

  @override
  String toString() => 'Doctor profile not found';
}

/// Provider for the Doctor repository singleton.
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(dioClientProvider));
});

/// Handles all doctor-specific API interactions:
/// - Profile management (GET/PUT)
/// - Registration (POST /api/doctors/register)
/// - KYC status retrieval (GET /api/doctors/kyc/status)
/// - KYC document metadata submission (POST /api/doctors/kyc/documents)
/// - NMC verification trigger (POST /api/doctors/kyc/verify-nmc)
class DoctorRepository {
  final Dio _dio;

  DoctorRepository(this._dio);

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Registers the currently authenticated user as a doctor.
  /// Backend: POST /api/doctors/register
  Future<DoctorProfile> register({
    required String specialization,
    required double consultationFee,
    required String licenseNumber,
    String? firstName,
    String? lastName,
    String? qualification,
    int? experienceYears,
    String? bio,
    List<String>? languagesSpoken,
    String? licenseIssuingAuthority,
    String? degree,
    String? degreeInstitution,
    int? degreeYear,
    int? registrationYear,
    String? stateMedicalCouncil,
    String? aadhaarLastFour,
  }) async {
    final response = await _dio.post('/api/doctors/register', data: {
      'first_name': ?firstName,
      'last_name': ?lastName,
      'specialization': specialization,
      'qualification': ?qualification,
      'experience_years': ?experienceYears,
      'bio': ?bio,
      'languages_spoken': ?languagesSpoken,
      'license_number': licenseNumber,
      'license_issuing_authority': ?licenseIssuingAuthority,
      'consultation_fee': consultationFee,
      'degree': ?degree,
      'degree_institution': ?degreeInstitution,
      'degree_year': ?degreeYear,
      'registration_year': ?registrationYear,
      'state_medical_council': ?stateMedicalCouncil,
      'aadhaar_last_four': ?aadhaarLastFour,
    });
    return DoctorProfile.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Fetches the profile for the currently authenticated doctor.
  /// Backend: GET /api/doctors/profile
  Future<DoctorProfile> getProfile() async {
    try {
      final response = await _dio.get('/api/doctors/profile');
      return DoctorProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Backend returns 404 when JWT is valid but no doctor row exists.
      // 401 means missing/invalid/expired session — do not treat as "no profile".
      if (e.response?.statusCode == 404) {
        throw const DoctorProfileNotFoundException();
      }
      rethrow;
    }
  }

  /// Updates profile fields for the currently authenticated doctor.
  /// Backend: PUT /api/doctors/profile
  Future<DoctorProfile> updateProfile({
    required String specialization,
    required double consultationFee,
    String? firstName,
    String? lastName,
    String? qualification,
    int? experienceYears,
    String? bio,
    String? licenseNumber,
    String? stateMedicalCouncil,
    String? degree,
    String? degreeInstitution,
    int? degreeYear,
    int? registrationYear,
  }) async {
    final response = await _dio.put('/api/doctors/profile', data: {
      'first_name': ?firstName,
      'last_name': ?lastName,
      'specialization': specialization,
      'qualification': ?qualification,
      'experience_years': ?experienceYears,
      'bio': ?bio,
      'license_number': ?licenseNumber,
      'state_medical_council': ?stateMedicalCouncil,
      'consultation_fee': consultationFee,
      'degree': ?degree,
      'degree_institution': ?degreeInstitution,
      'degree_year': ?degreeYear,
      'registration_year': ?registrationYear,
    });
    return DoctorProfile.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // KYC
  // ---------------------------------------------------------------------------

  /// Retrieves the full KYC status including submitted documents.
  /// Backend: GET /api/doctors/kyc/status
  Future<Map<String, dynamic>> getKycStatus() async {
    final response = await _dio.get('/api/doctors/kyc/status');
    return response.data as Map<String, dynamic>;
  }

  /// Submits metadata for an already-uploaded KYC document.
  /// The [garageObjectUuid] is the UUID extracted from the upload URL key.
  /// Backend: POST /api/doctors/kyc/documents
  Future<Map<String, dynamic>> submitKycDocumentMetadata({
    required String documentType,
    required String fileName,
    required String garageObjectUuid,
    String? mimeType,
  }) async {
    final response = await _dio.post('/api/doctors/kyc/documents', data: {
      'document_type': documentType,
      'file_name': fileName,
      'garage_object_uuid': garageObjectUuid,
      'mime_type': ?mimeType,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Gets a presigned PUT URL for uploading a KYC document to storage.
  /// Backend: POST /api/compliance/upload-url
  Future<Map<String, dynamic>> getUploadUrl({
    required String fileName,
    required String contentType,
  }) async {
    final response = await _dio.post('/api/compliance/upload-url', data: {
      'file_name': fileName,
      'content_type': contentType,
    });
    return response.data as Map<String, dynamic>;
  }
}
