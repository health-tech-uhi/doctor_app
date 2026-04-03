import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../core/ui/adaptive/adaptive_widgets.dart';
import '../../../core/ui/feedback/app_status_panel.dart';
import '../../doctor/providers/doctor_providers.dart';
import '../../kyc/domain/kyc_document.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/domain/auth_state.dart';

/// KYC gating screen shown to all authenticated doctors who are not yet verified.
/// Displays a clear progress-based checklist guiding the doctor through:
///   1. Submitting KYC documents
///   2. Joining the video verification call
///   3. Awaiting admin approval
class KycShellScreen extends ConsumerStatefulWidget {
  const KycShellScreen({super.key});

  @override
  ConsumerState<KycShellScreen> createState() => _KycShellScreenState();
}

class _KycShellScreenState extends ConsumerState<KycShellScreen> {
  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycStatusProvider);
    final authState = ref.watch(authNotifierProvider);

    // If admin verified us while the screen was open — re-route automatically
    if (authState.verificationStatus == VerificationStatus.verified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: kycAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.tealAccent),
          ),
          error: (e, _) => _buildError(
            userFacingErrorMessage(e, context: ErrorUxContext.kyc),
          ),
          data: (kycStatus) => _buildContent(kycStatus),
        ),
      ),
    );
  }

  Widget _buildContent(KycStatus kycStatus) {
    final docsSubmitted = kycStatus.documents.isNotEmpty;
    final progress = _calculateProgress(kycStatus);

    return RefreshIndicator(
      color: Colors.tealAccent,
      backgroundColor: const Color(0xFF131929),
      onRefresh: () async {
        await ref.read(kycStatusProvider.notifier).refresh();
        await ref
            .read(authNotifierProvider.notifier)
            .refreshVerificationStatus();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(progress, kycStatus)),
          SliverToBoxAdapter(child: _buildStepsList(kycStatus, docsSubmitted)),
          if (docsSubmitted)
            SliverToBoxAdapter(child: _buildDocumentList(kycStatus.documents)),
          SliverToBoxAdapter(child: _buildRejectedBanner(kycStatus)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  double _calculateProgress(KycStatus kycStatus) {
    if (kycStatus.isVerified) return 1.0;
    if (kycStatus.documents.isNotEmpty) return 0.66;
    return 0.33;
  }

  Widget _buildHero(double progress, KycStatus kycStatus) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.tealAccent.withValues(alpha: 0.12),
            Colors.indigo.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 8,
            percent: progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Complete',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            progressColor: Colors.tealAccent,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 20),
          const Text(
            'Identity Verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kycStatus.isRejected
                ? 'Your application was rejected. Please resubmit.'
                : 'Complete the steps below to access the platform.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList(KycStatus kycStatus, bool docsSubmitted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Steps',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildStep(
            index: 1,
            title: 'Submit Documents',
            subtitle: docsSubmitted
                ? '${kycStatus.documents.length} document(s) submitted'
                : 'Upload your medical license & ID proof',
            isCompleted: docsSubmitted,
            isActive: !docsSubmitted,
            onTap: () => context.go('/kyc/upload'),
          ),
          _buildConnector(isCompleted: docsSubmitted),
          _buildStep(
            index: 2,
            title: 'Video verification',
            subtitle:
                'Optional — follow instructions if your reviewer requests a call',
            isCompleted: false,
            isActive: docsSubmitted,
            onTap: docsSubmitted ? () => context.go('/kyc/call') : null,
          ),
          _buildConnector(isCompleted: false),
          _buildStep(
            index: 3,
            title: 'Admin Approval',
            subtitle: 'Usually within 2–3 business days',
            isCompleted: kycStatus.isVerified,
            isActive: false,
            onTap: null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int index,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final color = isCompleted
        ? Colors.tealAccent
        : isActive
        ? Colors.white
        : Colors.white30;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.tealAccent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? Colors.tealAccent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.tealAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.07),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.tealAccent,
                        size: 18,
                      )
                    : Text(
                        '$index',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color == Colors.white30
                          ? Colors.white38
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color == Colors.white30
                          ? Colors.white24
                          : Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.tealAccent,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 35),
      width: 2,
      height: 16,
      color: isCompleted
          ? Colors.tealAccent.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildDocumentList(List<KycDocument> docs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Submitted Documents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...docs.map((doc) => _buildDocCard(doc)),
        ],
      ),
    );
  }

  Widget _buildDocCard(KycDocument doc) {
    final statusColor = doc.status == 'approved'
        ? Colors.tealAccent
        : doc.status == 'rejected'
        ? Colors.redAccent
        : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: Colors.white54,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  doc.documentType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              doc.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(KycStatus kycStatus) {
    if (!kycStatus.isRejected) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your application was rejected. Please resubmit your documents and try again.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppStatusPanel(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn\'t load verification status',
          message: message,
          iconColor: Theme.of(context).colorScheme.error,
          primaryAction: AdaptivePrimaryButton(
            onPressed: () => ref.refresh(kycStatusProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}
