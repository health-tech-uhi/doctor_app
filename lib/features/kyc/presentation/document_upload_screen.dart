import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../core/ui/adaptive/adaptive_app_bar.dart';
import '../../../core/ui/adaptive/adaptive_widgets.dart';
import '../../kyc/data/kyc_upload_repository.dart';
import '../../doctor/providers/doctor_providers.dart';

/// Document types accepted by the KYC process.
/// Mirrors the `document_type` field expected by the backend.
enum KycDocumentType {
  medicalLicense('medical_license', 'Medical License', Icons.badge_outlined),
  degreeCertificate(
    'degree_certificate',
    'Degree Certificate',
    Icons.school_outlined,
  ),
  idProof('id_proof', 'Government ID Proof', Icons.credit_card_outlined),
  registrationCertificate(
    'registration_certificate',
    'NMC Registration Certificate',
    Icons.article_outlined,
  );

  const KycDocumentType(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

/// State for the upload form.
class _UploadState {
  final KycDocumentType? selectedType;
  final PlatformFile? selectedFile;
  final bool isUploading;
  final String? errorMessage;
  final bool isSuccess;

  const _UploadState({
    this.selectedType,
    this.selectedFile,
    this.isUploading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  _UploadState copyWith({
    KycDocumentType? selectedType,
    PlatformFile? selectedFile,
    bool? isUploading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return _UploadState(
      selectedType: selectedType ?? this.selectedType,
      selectedFile: selectedFile ?? this.selectedFile,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Document upload screen for KYC verification.
/// Allows the doctor to:
///  1. Select a document type
///  2. Pick a file from their device
///  3. Upload via the 3-step presigned URL flow
class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  _UploadState _state = const _UploadState();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // Load file bytes into memory for upload
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _state = _state.copyWith(
          selectedFile: result.files.first,
          errorMessage: null,
        );
      });
    }
  }

  Future<void> _upload() async {
    if (_state.selectedType == null) {
      setState(() {
        _state = _state.copyWith(
          errorMessage: 'Please select a document type.',
        );
      });
      return;
    }
    if (_state.selectedFile == null || _state.selectedFile!.bytes == null) {
      setState(() {
        _state = _state.copyWith(
          errorMessage: 'Please select a file to upload.',
        );
      });
      return;
    }

    setState(() {
      _state = _state.copyWith(isUploading: true, errorMessage: null);
    });

    try {
      final file = _state.selectedFile!;
      final mimeType = _mimeTypeForExtension(file.extension);

      await ref
          .read(kycUploadRepositoryProvider)
          .uploadDocument(
            fileBytes: file.bytes!,
            fileName: file.name,
            mimeType: mimeType,
            documentType: _state.selectedType!.value,
          );

      // Refresh the KYC status so the shell screen reflects the new document
      await ref.read(kycStatusProvider.notifier).refresh();

      if (mounted) {
        setState(() => _state = _state.copyWith(isSuccess: true));

        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) context.go('/kyc');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(
            isUploading: false,
            errorMessage: userFacingErrorMessage(
              e,
              context: ErrorUxContext.kyc,
            ),
          );
        });
      }
    }
  }

  String _mimeTypeForExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AdaptiveAppBar.forScreen(
        context,
        title: 'Upload Document',
        leading: IconButton(
          tooltip: 'Back to verification',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => context.go('/kyc'),
        ),
      ),
      body: SafeArea(
        child: _state.isSuccess ? _buildSuccessState() : _buildUploadForm(),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.tealAccent.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.tealAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Document Uploaded!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Redirecting back to KYC overview...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Document Type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTypeSelector(),
          const SizedBox(height: 28),
          const Text(
            'Select File',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilePicker(),
          if (_state.errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _state.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          _buildFormatInfo(),
          const SizedBox(height: 32),
          _buildUploadButton(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: KycDocumentType.values.map((type) {
        final isSelected = _state.selectedType == type;
        return GestureDetector(
          onTap: () =>
              setState(() => _state = _state.copyWith(selectedType: type)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.tealAccent.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.tealAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  type.icon,
                  color: isSelected ? Colors.tealAccent : Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    type.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.tealAccent,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilePicker() {
    final file = _state.selectedFile;
    return GestureDetector(
      onTap: _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: file != null
              ? Colors.tealAccent.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file != null
                ? Colors.tealAccent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.12),
            style: file != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: file != null
            ? Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: Colors.tealAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(file.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.swap_horiz, color: Colors.white38, size: 20),
                ],
              )
            : Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white38,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap to select a file',
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PDF, JPG or PNG',
                    style: TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormatInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Accepted: PDF, JPG, PNG · Max size: 50MB · Ensure the document is clearly legible.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return AdaptivePrimaryButton(
      minHeight: 54,
      onPressed: _state.isUploading ? null : _upload,
      child: _state.isUploading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : const Text(
              'Upload Document',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }
}
