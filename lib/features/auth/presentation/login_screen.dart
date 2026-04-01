import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/feedback/app_snack_bar.dart';
import '../../../core/ui/glass/app_gradients.dart';
import '../../../core/ui/glass/aurora_background.dart';
import '../../../core/ui/glass/glass_card.dart';
import '../providers/auth_provider.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    final username = _usernameController.text;
    final password = _passwordController.text;
    if (username.isNotEmpty && password.isNotEmpty) {
      ref.read(authNotifierProvider.notifier).login(username, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        AppSnackBar.show(context, next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AuroraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 48),
                _buildLoginForm(isLoading),
                const SizedBox(height: 32),
                _buildSignupPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.auroraPrimary,
            boxShadow: [
              BoxShadow(color: AppGradients.cyanMint.withOpacity(0.3), blurRadius: 40, spreadRadius: 5),
            ],
          ),
          child: const Icon(Icons.health_and_safety_rounded, size: 48, color: Colors.black),
        ),
        const SizedBox(height: 24),
        const Text(
          'AESTHETIQ',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4),
        ),
        const Text(
          'CLINICAL PORTAL',
          style: TextStyle(color: AppGradients.cyanMint, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Secure Sign In',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureText,
            suffix: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white30),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
          const SizedBox(height: 32),
          _buildLoginButton(isLoading),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: AppGradients.cyanMint.withOpacity(0.5), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
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
        onPressed: isLoading ? null : _onLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Text(
                'AUTHENTICATE',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
      ),
    );
  }

  Widget _buildSignupPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('New to the portal? ', style: TextStyle(color: Colors.white38)),
        TextButton(
          onPressed: () => context.push('/signup'),
          child: const Text(
            'JOIN NOW',
            style: TextStyle(color: AppGradients.cyanMint, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}
