import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

/// Provider for the KYC upload repository.
final kycUploadRepositoryProvider = Provider<KycUploadRepository>((ref) {
  return KycUploadRepository(ref.watch(dioClientProvider));
});

/// Orchestrates the 3-step document upload flow used in KYC:
/// 1. Request a presigned PUT URL from the backend
/// 2. Upload the raw file bytes directly to Garage storage via the signed URL
/// 3. Submit document metadata to the backend (including the garage_object_uuid)
///
/// This mirrors the pattern from the patient web app's record upload action.
class KycUploadRepository {
  final Dio _dio;

  KycUploadRepository(this._dio);

  /// Full end-to-end upload for a KYC document.
  ///
  /// Returns the [garageObjectUuid] that was uploaded, which is needed
  /// for the subsequent metadata registration call.
  ///
  /// [fileBytes] — raw file content read from the device
  /// [fileName] — display name for the file
  /// [mimeType] — content type (e.g. 'application/pdf')
  /// [documentType] — semantic type e.g. 'license', 'degree', 'id_proof'
  Future<String> uploadDocument({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    required String documentType,
  }) async {
    // Step 1 — get presigned upload URL from backend
    final urlResponse = await _dio.post(
      '/api/compliance/upload-url',
      data: {'file_name': fileName, 'content_type': mimeType},
    );
    final uploadUrl = urlResponse.data['url'] as String;
    final key = urlResponse.data['key'] as String;

    // Step 2 — PUT the raw bytes directly to storage
    // We use a plain Dio instance (no auth interceptor) for storage uploads
    final storageDio = Dio();
    await storageDio.put(
      uploadUrl,
      data: Stream.fromIterable(fileBytes.map((b) => [b])),
      options: Options(
        headers: {'Content-Type': mimeType, 'Content-Length': fileBytes.length},
        // Treat any 2xx as success
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    // Step 3 — Extract the UUID from the storage key (pattern: "folder/uuid")
    final parts = key.split('/');
    final garageObjectUuid = parts.length >= 2 ? parts[1] : parts.last;

    // Step 4 — Register document metadata with the backend
    await _dio.post(
      '/api/doctors/kyc/documents',
      data: {
        'document_type': documentType,
        'file_name': fileName,
        'garage_object_uuid': garageObjectUuid,
        'mime_type': mimeType,
      },
    );

    return garageObjectUuid;
  }
}
