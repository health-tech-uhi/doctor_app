import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/doctor_theme.dart';
import '../../../../core/ui/glass/aurora_background.dart';
import '../../../../core/ui/glass/glass_card.dart';
import '../../../doctor/providers/doctor_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../doctor/data/doctor_repository.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState.requiresProfileCompletion) {
      return AuroraBackground(
        child: Center(
          child: _buildErrorState(
            context,
            ref,
            const DoctorProfileNotFoundException(),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBackground,
      body: AuroraBackground(
        child: profileAsync.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => _buildErrorState(context, ref, e),
          data: (profile) => _buildContent(context, ref, profile),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic profile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        children: [
          const SizedBox(height: 72),
          _buildHero(profile),
          const SizedBox(height: 32),
          _buildInfoSection(profile),
          const SizedBox(height: 32),
          _buildSettingsList(context, ref),
        ],
      ),
    );
  }

  Widget _buildHero(dynamic profile) {
    return Column(
      children: [
        _buildLargeAvatar(profile.fullName),
        const SizedBox(height: 20),
        Text(
          'Dr. ${profile.fullName}',
          style: const TextStyle(
            color: DoctorTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          profile.specialization.toUpperCase(),
          style: const TextStyle(
            color: DoctorTheme.accentCyan,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        _verifiedBadge(profile.verificationStatus as String?),
      ],
    );
  }

  Widget _buildLargeAvatar(String name) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: DoctorTheme.profileGradient,
        border: Border.all(
          color: DoctorTheme.accentCyan.withOpacity(0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: DoctorTheme.accentCyan.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _verifiedBadge(String? verificationStatus) {
    final status = (verificationStatus ?? 'pending').toLowerCase();
    final isVerified = status == 'verified';
    final label = isVerified ? 'Verified Professional' : 'Verification Pending';

    // Color logic as per user request for pending state
    final color = isVerified ? DoctorTheme.accentCyan : const Color(0xFFFFB74D);
    final bgColor = isVerified
        ? color.withValues(alpha: 0.1)
        : const Color.fromRGBO(255, 152, 0, 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified
                ? Icons.verified_user_rounded
                : Icons.pending_actions_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(dynamic profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'PROFESSIONAL OVERVIEW',
            style: TextStyle(
              color: DoctorTheme.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _infoRow(
          Icons.history_edu_rounded,
          'Experience',
          '${profile.experienceYears ?? 'N/A'} Years',
        ),
        _infoRow(
          Icons.currency_rupee_rounded,
          'Consultation',
          '₹${profile.consultationFeeInr?.toStringAsFixed(0) ?? 'N/A'}',
        ),
        _infoRow(
          Icons.document_scanner_rounded,
          'License No.',
          _displayOrMissing(profile.licenseNumber),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DoctorTheme.accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: DoctorTheme.accentCyan, size: 18),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: DoctorTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: DoctorTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'ACCOUNT & PREFERENCES',
            style: TextStyle(
              color: DoctorTheme.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _settingRow(
          context,
          Icons.person_outline_rounded,
          'Edit Profile Details',
          () => context.push('/profile/edit'),
        ),
        _settingRow(
          context,
          Icons.verified_user_outlined,
          'KYC & Verification',
          () => context.push('/profile/kyc'),
        ),
        _settingRow(
          context,
          Icons.notifications_none_rounded,
          'Reminders & Notifications',
          () {},
        ),
        const SizedBox(height: 24),
        _buildLogoutButton(ref),
      ],
    );
  }

  Widget _settingRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: DoctorTheme.textTertiary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: DoctorTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DoctorTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return GlassCard(
      onTap: () => ref.read(authNotifierProvider.notifier).logout(),
      color: const Color(0xFFFF4B4B).withOpacity(0.06),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.power_settings_new_rounded,
            color: Color(0xFFFF4B4B),
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFFFF4B4B),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: DoctorTheme.accentCyan,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final isMissing = error is DoctorProfileNotFoundException;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DoctorTheme.accentCyan.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMissing ? Icons.person_search_rounded : Icons.cloud_off_rounded,
              size: 56,
              color: DoctorTheme.accentCyan,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isMissing ? 'Profile Incomplete' : 'Network Error',
            style: const TextStyle(
              color: DoctorTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isMissing
                ? 'Please finalize your professional details to access your dashboard.'
                : 'Unable to reach clinical servers. Please check your connection.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DoctorTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isMissing
                  ? () => context.push('/complete-profile')
                  : () => ref.refresh(doctorProfileProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: DoctorTheme.accentCyan,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isMissing ? 'Finalize Profile' : 'Retry Connection',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String _displayOrMissing(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not Verified';
    return value;
  }
}
