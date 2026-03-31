import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/adaptive/adaptive_app_bar.dart';
import '../../../core/ui/adaptive/adaptive_widgets.dart';
import '../../../core/ui/feedback/app_snack_bar.dart';
import '../../../core/ui/feedback/app_status_panel.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor_profile.dart';
import '../providers/doctor_providers.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _councilCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _registrationYearCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _submitting = false;
  bool _profileSaved = false;
  bool _seeded = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _specializationCtrl.dispose();
    _feeCtrl.dispose();
    _experienceCtrl.dispose();
    _licenseCtrl.dispose();
    _councilCtrl.dispose();
    _degreeCtrl.dispose();
    _institutionCtrl.dispose();
    _registrationYearCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _seedFromProfile(DoctorProfile p) {
    if (_seeded) return;
    final parts = p.fullName.trim().split(RegExp(r'\s+'));
    _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
    _lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _specializationCtrl.text = p.specialization;
    _feeCtrl.text = p.consultationFeeInr?.toStringAsFixed(0) ?? '';
    _experienceCtrl.text = p.experienceYears?.toString() ?? '';
    _licenseCtrl.text = p.licenseNumber ?? '';
    _councilCtrl.text = p.stateMedicalCouncil ?? '';
    _degreeCtrl.text = p.degree ?? '';
    _institutionCtrl.text = p.degreeInstitution ?? '';
    _registrationYearCtrl.text = p.registrationYear?.toString() ?? '';
    _bioCtrl.text = p.bio ?? '';
    _seeded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final repo = ref.read(doctorRepositoryProvider);
    final profileAsync = ref.read(doctorProfileProvider);
    final shouldUpdate = profileAsync.hasValue;

    try {
      if (shouldUpdate) {
        await _putProfileUpdate(repo);
      } else {
        try {
          await _postProfileRegister(repo);
        } on DioException catch (e) {
          // Already registered (e.g. another device) — persist edits via PUT.
          if (e.response?.statusCode == 409) {
            await _putProfileUpdate(repo);
          } else {
            rethrow;
          }
        }
      }

      ref.invalidate(doctorProfileProvider);
      ref.invalidate(kycStatusProvider);

      if (mounted) {
        setState(() => _profileSaved = true);
        AppSnackBar.show(context, 'Profile saved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          userFacingErrorMessage(e, context: ErrorUxContext.profile),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _postProfileRegister(DoctorRepository repo) {
    return repo.register(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      specialization: _specializationCtrl.text.trim(),
      consultationFee: double.parse(_feeCtrl.text.trim()),
      experienceYears: int.tryParse(_experienceCtrl.text.trim()),
      licenseNumber: _licenseCtrl.text.trim(),
      stateMedicalCouncil: _councilCtrl.text.trim(),
      degree: _degreeCtrl.text.trim(),
      degreeInstitution: _institutionCtrl.text.trim(),
      registrationYear: int.parse(_registrationYearCtrl.text.trim()),
      bio: _bioCtrl.text.trim(),
    );
  }

  Future<void> _putProfileUpdate(DoctorRepository repo) {
    return repo.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      specialization: _specializationCtrl.text.trim(),
      consultationFee: double.parse(_feeCtrl.text.trim()),
      experienceYears: int.tryParse(_experienceCtrl.text.trim()),
      licenseNumber: _licenseCtrl.text.trim(),
      stateMedicalCouncil: _councilCtrl.text.trim(),
      degree: _degreeCtrl.text.trim(),
      degreeInstitution: _institutionCtrl.text.trim(),
      registrationYear: int.parse(_registrationYearCtrl.text.trim()),
      bio: _bioCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileAsync = ref.watch(doctorProfileProvider);
    final hasProfile = profileAsync.hasValue;
    final profileReady = _profileSaved || hasProfile;

    /// Auth already ran GET /api/doctors/profile during hydration; do not block the UI on
    /// [AsyncLoading] while the provider catches up (avoids long spinner when opening this route).
    final knownMissingProfile = authState.requiresProfileCompletion ||
        profileAsync.maybeWhen(
          error: (e, _) => e is DoctorProfileNotFoundException,
          orElse: () => false,
        );

    Widget body;
    if (knownMissingProfile) {
      if (profileAsync.hasValue) {
        _seedFromProfile(profileAsync.requireValue);
      }
      body = _profileFormBody(
        profileReady: profileReady,
        isUpdateMode: profileAsync.hasValue,
      );
    } else {
      body = profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
        error: (e, _) {
          if (e is DoctorProfileNotFoundException) {
            return _profileFormBody(
              profileReady: profileReady,
              isUpdateMode: false,
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppStatusPanel(
                icon: Icons.cloud_off_rounded,
                title: 'Couldn\'t load profile',
                message: userFacingErrorMessage(e, context: ErrorUxContext.profile),
                iconColor: Theme.of(context).colorScheme.error,
                primaryAction: AdaptivePrimaryButton(
                  onPressed: () => ref.invalidate(doctorProfileProvider),
                  child: const Text('Try again'),
                ),
              ),
            ),
          );
        },
        data: (profile) {
          _seedFromProfile(profile);
          return _profileFormBody(
            profileReady: profileReady,
            isUpdateMode: true,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AdaptiveAppBar.forScreen(context, title: 'Complete Profile'),
      body: body,
    );
  }

  Widget _profileFormBody({
    required bool profileReady,
    required bool isUpdateMode,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Doctor Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profileReady
                    ? 'Your professional profile is ready. You can continue with verification now or come back to it later.'
                    : 'A quick step to introduce your practice—then you can continue with verification.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Basic Information',
                children: [
                  _field(_firstNameCtrl, 'First name', required: true),
                  _field(_lastNameCtrl, 'Last name', required: true),
                  _field(_specializationCtrl, 'Specialization', required: true),
                  _field(
                    _feeCtrl,
                    'Consultation fee (INR)',
                    required: true,
                    number: true,
                  ),
                  _field(
                    _experienceCtrl,
                    'Years of experience (optional)',
                    number: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'Professional Information',
                children: [
                  _field(_licenseCtrl, 'License number', required: true),
                  _field(
                    _councilCtrl,
                    'State medical council',
                    required: true,
                  ),
                  _field(_degreeCtrl, 'Degree', required: true),
                  _field(
                    _institutionCtrl,
                    'Degree institution',
                    required: true,
                  ),
                  _field(
                    _registrationYearCtrl,
                    'NMC registration year',
                    required: true,
                    number: true,
                  ),
                  _multilineField(_bioCtrl, 'Bio', required: true),
                ],
              ),
              const SizedBox(height: 18),
              AdaptivePrimaryButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isUpdateMode || _profileSaved
                        ? 'Update Profile'
                        : 'Save Profile'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: profileReady
                    ? () => context.push('/kyc')
                    : null,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Continue to Verification'),
              ),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: const Text('Do this later'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
        ),
        validator: (v) {
          final value = (v ?? '').trim();
          if (required && value.isEmpty) return '$label is required';
          if (number && value.isNotEmpty && double.tryParse(value) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _multilineField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
        ),
        validator: required
            ? (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return '$label is required';
                return null;
              }
            : null,
      ),
    );
  }
}
