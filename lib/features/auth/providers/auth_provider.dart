import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/errors/user_facing_error.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../doctor/data/doctor_repository.dart';
import '../../doctor/providers/doctor_providers.dart';

/// Provider exposing the central AuthNotifier logic to be mapped with State.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Tracks and orchestrates changes to the AuthState.
/// After authentication, it automatically fetches the doctor's verification status
/// from the backend to drive KYC-aware routing.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  late final DoctorRepository _doctorRepository;
  late final bool _kycEnabled;
  bool _scheduledInitialCheck = false;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _doctorRepository = ref.watch(doctorRepositoryProvider);
    _kycEnabled = ref.watch(kycFeatureEnabledProvider);

    // Asynchronously verify local token presence after build cycle completes
    if (!_scheduledInitialCheck) {
      _scheduledInitialCheck = true;
      Future.microtask(() => checkInitialStatus());
    }

    return const AuthState();
  }

  /// On startup: checks for a saved token, then fetches the doctor profile to
  /// determine whether the doctor is KYC-verified or still pending.
  Future<void> checkInitialStatus() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (!isAuth) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    await _hydratePostLoginState();
  }

  /// Calls repository login with credentials and fetches verification status on success.
  Future<void> login(String username, String password) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearErrorMessage: true,
    );
    try {
      await _authRepository.login(username, password);
      await _hydratePostLoginState();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userFacingErrorMessage(e, context: ErrorUxContext.login),
      );
    }
  }

  /// After signup, the user is authenticated but always pending verification.
  Future<void> onRegistrationComplete() async {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      clearErrorMessage: true,
      verificationStatus:
          _kycEnabled ? VerificationStatus.pending : VerificationStatus.unknown,
    );
  }

  /// Fetches profile once after auth and derives both verification + profile-completion state.
  /// Seeds [doctorProfileProvider] so the dashboard does not fire a duplicate GET.
  Future<void> _hydratePostLoginState() async {
    try {
      await _authRepository.switchToDoctorProfileContext();
      final profile = await _doctorRepository.getProfile();
      DoctorProfileNotifier.preparePendingHydration(AsyncData(profile));
      ref
          .read(doctorProfileProvider.notifier)
          .seedFromHydration(AsyncData(profile));
      state = state.copyWith(
        status: AuthStatus.authenticated,
        clearErrorMessage: true,
        requiresProfileCompletion: false,
        verificationStatus: _kycEnabled
            ? verificationStatusFromString(profile.verificationStatus)
            : VerificationStatus.unknown,
      );
    } on DoctorProfileNotFoundException catch (e, st) {
      // Auth identity exists, but doctor profile is not onboarded yet.
      DoctorProfileNotifier.preparePendingHydration(AsyncError(e, st));
      ref
          .read(doctorProfileProvider.notifier)
          .seedFromHydration(AsyncError(e, st));
      state = state.copyWith(
        status: AuthStatus.authenticated,
        clearErrorMessage: true,
        requiresProfileCompletion: true,
        verificationStatus:
            _kycEnabled ? VerificationStatus.pending : VerificationStatus.unknown,
      );
    } catch (_) {
      // Keep user authenticated, but do not force profile onboarding on transient API errors.
      // Do not seed — [doctorProfileProvider] will load on first watch (single GET).
      state = state.copyWith(
        status: AuthStatus.authenticated,
        clearErrorMessage: true,
        requiresProfileCompletion: false,
        verificationStatus:
            _kycEnabled ? VerificationStatus.pending : VerificationStatus.unknown,
      );
    }
  }

  /// Polls the backend for a fresh verification status.
  /// Used on the KYC screen to check if admin has approved the doctor.
  Future<void> refreshVerificationStatus() async {
    if (_kycEnabled) {
      await _hydratePostLoginState();
    }
  }

  /// Securely handles terminating local tokens.
  Future<void> logout() async {
    await _authRepository.logout();
    DoctorProfileNotifier.clearPendingHydration();
    ref.invalidate(doctorProfileProvider);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
