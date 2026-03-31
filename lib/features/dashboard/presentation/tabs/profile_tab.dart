import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/feedback/app_status_panel.dart';
import '../../../doctor/providers/doctor_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../doctor/data/doctor_repository.dart';

/// Profile tab — shows the doctor's personal & professional details with logout.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState.requiresProfileCompletion) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildErrorState(
              context,
              ref,
              const DoctorProfileNotFoundException(),
            ),
          ),
        ],
      );
    }

    final profileAsync = ref.watch(doctorProfileProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: profileAsync.when(
            loading: () => _buildSkeleton(),
            error: (e, _) => _buildErrorState(context, ref, e),
            data: (profile) => _buildContent(context, ref, profile),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic profile) {
    return Column(
      children: [
        _buildHero(profile),
        _buildInfoSection(profile),
        _buildSettingsList(context, ref),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHero(dynamic profile) {
    final initials = _initials(profile.fullName);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.tealAccent, Color(0xFF00897B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.tealAccent.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. ${profile.fullName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.specialization,
            style: const TextStyle(color: Colors.tealAccent, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _verifiedBadge(profile.verificationStatus as String?),
        ],
      ),
    );
  }

  Widget _verifiedBadge(String? verificationStatus) {
    final status = (verificationStatus ?? 'pending').toLowerCase();
    final isVerified = status == 'verified';
    final isRejected = status == 'rejected';
    final label = isVerified
        ? 'KYC Verified'
        : isRejected
            ? 'KYC Rejected'
            : 'KYC Pending';
    final color = isVerified
        ? Colors.tealAccent
        : isRejected
            ? Colors.redAccent
            : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Info',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.work_outline, 'Experience',
              '${profile.experienceYears ?? 'N/A'} years'),
          _infoRow(Icons.currency_rupee, 'Consultation Fee',
              '₹${profile.consultationFeeInr?.toStringAsFixed(0) ?? 'N/A'}'),
          _infoRow(Icons.badge_outlined, 'License No.',
              _displayOrMissing(profile.licenseNumber)),
          _infoRow(Icons.verified_user_outlined, 'License Authority',
              _displayOrMissing(profile.licenseIssuingAuthority)),
          _infoRow(Icons.school_outlined, 'Degree', _displayOrMissing(profile.degree)),
          _infoRow(Icons.account_balance_outlined, 'Degree Institution',
              _displayOrMissing(profile.degreeInstitution)),
          _infoRow(Icons.calendar_month_outlined, 'Registration Year',
              profile.registrationYear?.toString() ?? 'Not provided'),
          _infoRow(Icons.gavel_outlined, 'Medical Council',
              _displayOrMissing(profile.stateMedicalCouncil)),
          _infoRow(Icons.notes_outlined, 'Bio', _displayOrMissing(profile.bio)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          _settingRow(
            icon: Icons.edit_note_rounded,
            label: 'Edit Profile / Fill Missing Info',
            // Push (not go) so the dashboard shell stays under this route and Back returns to tabs.
            onTap: () => context.push('/profile/edit'),
          ),
          _settingRow(
            icon: Icons.verified_user_outlined,
            label: 'Complete KYC',
            onTap: () => context.push('/profile/kyc'),
          ),
          _settingRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          _settingRow(
            icon: Icons.lock_outline,
            label: 'Privacy & Security',
            onTap: () {},
          ),
          _settingRow(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          // Logout
          GestureDetector(
            onTap: () => ref.read(authNotifierProvider.notifier).logout(),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.redAccent, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const SizedBox(height: 64),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 180,
            height: 22,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        const SizedBox(height: 60),
        const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final profileMissing = error is DoctorProfileNotFoundException;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        child: AppStatusPanel(
          icon: profileMissing ? Icons.person_add_alt_1 : Icons.error_outline,
          title: profileMissing
              ? 'Profile not set up yet'
              : 'Couldn\'t load your profile',
          message: profileMissing
              ? 'Add your professional details so patients can find you and you can finish verification.'
              : 'Check your connection and try again. If this keeps happening, contact support.',
          iconColor: profileMissing
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          primaryAction: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: profileMissing
                  ? () => context.push('/complete-profile')
                  : () => ref.refresh(doctorProfileProvider),
              icon: Icon(profileMissing ? Icons.edit_note : Icons.refresh),
              label: Text(profileMissing ? 'Complete profile' : 'Retry'),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String _displayOrMissing(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not provided';
    return value;
  }
}
