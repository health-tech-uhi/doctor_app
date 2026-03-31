import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../core/ui/adaptive/adaptive_app_bar.dart';
import '../../../core/ui/adaptive/adaptive_widgets.dart';
import '../../../core/ui/feedback/app_snack_bar.dart';
import '../../../core/ui/feedback/app_status_panel.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor_profile.dart';
import '../providers/doctor_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _registrationYearCtrl = TextEditingController();
  final _councilCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _specializationCtrl.dispose();
    _feeCtrl.dispose();
    _experienceCtrl.dispose();
    _licenseCtrl.dispose();
    _degreeCtrl.dispose();
    _institutionCtrl.dispose();
    _registrationYearCtrl.dispose();
    _councilCtrl.dispose();
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
    _degreeCtrl.text = p.degree ?? '';
    _institutionCtrl.text = p.degreeInstitution ?? '';
    _registrationYearCtrl.text = p.registrationYear?.toString() ?? '';
    _councilCtrl.text = p.stateMedicalCouncil ?? '';
    _bioCtrl.text = p.bio ?? '';
    _seeded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(doctorRepositoryProvider).updateProfile(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            specialization: _specializationCtrl.text.trim(),
            consultationFee: double.parse(_feeCtrl.text.trim()),
            experienceYears: int.tryParse(_experienceCtrl.text.trim()),
            licenseNumber: _licenseCtrl.text.trim(),
            degree: _degreeCtrl.text.trim(),
            degreeInstitution: _institutionCtrl.text.trim(),
            registrationYear: int.parse(_registrationYearCtrl.text.trim()),
            stateMedicalCouncil: _councilCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          );

      ref.invalidate(doctorProfileProvider);
      if (mounted) {
        AppSnackBar.show(context, 'Profile updated successfully');
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      appBar: AdaptiveAppBar.forScreen(context, title: 'Edit Profile'),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppStatusPanel(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn\'t load your profile',
              message: userFacingErrorMessage(e, context: ErrorUxContext.profile),
              iconColor: Theme.of(context).colorScheme.error,
              primaryAction: AdaptivePrimaryButton(
                onPressed: () => ref.invalidate(doctorProfileProvider),
                child: const Text('Try again'),
              ),
            ),
          ),
        ),
        data: (profile) {
          _seedFromProfile(profile);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(_firstNameCtrl, 'First name', required: true),
                    _field(_lastNameCtrl, 'Last name', required: true),
                    _field(_specializationCtrl, 'Specialization', required: true),
                    _field(_feeCtrl, 'Consultation fee', required: true, number: true),
                    _field(_experienceCtrl, 'Experience years', number: true),
                    _field(_licenseCtrl, 'License number', required: true),
                    _field(_degreeCtrl, 'Degree', required: true),
                    _field(_institutionCtrl, 'Degree institution', required: true),
                    _field(
                      _registrationYearCtrl,
                      'Registration year',
                      required: true,
                      number: true,
                    ),
                    _field(_councilCtrl, 'State medical council', required: true),
                    _multilineField(_bioCtrl, 'Bio', required: true),
                    const SizedBox(height: 18),
                    AdaptivePrimaryButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
          );
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
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(labelText: label),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
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
}

