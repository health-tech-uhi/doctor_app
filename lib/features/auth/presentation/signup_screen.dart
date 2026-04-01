import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:doctor_app/core/errors/user_facing_error.dart';
import 'package:doctor_app/core/ui/feedback/app_snack_bar.dart';
import 'package:doctor_app/features/auth/data/auth_repository.dart';
import 'package:doctor_app/features/auth/providers/auth_provider.dart';

import '../../../core/ui/glass/app_gradients.dart';
import '../../../core/ui/glass/aurora_background.dart';
import '../../../core/ui/glass/glass_card.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _otpSent = false;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      AppSnackBar.show(context, 'Please enter your email first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).generateOtp(
            identifier: _emailCtrl.text.trim(),
            channel: 'Email',
          );
      if (mounted) {
        setState(() => _otpSent = true);
        AppSnackBar.show(context, 'OTP sent to your email');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          userFacingErrorMessage(e, context: ErrorUxContext.signup),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_otpSent) {
      AppSnackBar.show(context, 'Please request OTP first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);

      await authRepo.verifyOtp(
        identifier: _emailCtrl.text.trim(),
        otp: _otpCtrl.text.trim(),
      );

      await authRepo.register(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await authRepo.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      await ref.read(authNotifierProvider.notifier).onRegistrationComplete();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          userFacingErrorMessage(e, context: ErrorUxContext.signup),
          isError: true,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSignupForm(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.05),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Join the Network',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const Text(
          'Verify your identity to get started',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(
            controller: _usernameCtrl,
            label: 'USERNAME',
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _emailCtrl,
            label: 'EMAIL ADDRESS',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _phoneCtrl,
            label: 'PHONE NUMBER',
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _passwordCtrl,
            label: 'SECURE PASSWORD',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) {
              if (v == null || v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _confirmPasswordCtrl,
            label: 'CONFIRM PASSWORD',
            icon: Icons.shield_outlined,
            obscureText: true,
            validator: (v) {
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildOtpSection(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: _otpCtrl,
                label: 'OTP CODE',
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length != 6) return '6 digits';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _otpSent ? Colors.white24 : AppGradients.cyanMint),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: _otpSent ? Colors.white70 : AppGradients.cyanMint,
                ),
                child: Text(_otpSent ? 'RESEND' : 'GET CODE'),
              ),
            ),
          ],
        ),
        if (_otpSent) ...[
          const SizedBox(height: 8),
          const Text(
            'Code sent to your email address',
            style: TextStyle(color: AppGradients.cyanMint, fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppGradients.cyanMint.withOpacity(0.5), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorStyle: const TextStyle(height: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppGradients.cyanMintGradient,
        boxShadow: [
          BoxShadow(color: AppGradients.cyanMint.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Text(
                'VERIFY & CREATE ACCOUNT',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
      ),
    );
  }
}
