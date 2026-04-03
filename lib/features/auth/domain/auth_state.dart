/// Represents the possible connection states for authentication.
/// - initial: App has just started, checking secure storage for saved tokens.
/// - unauthenticated: No valid session found.
/// - authenticating: Actively calling backend to verify credentials.
/// - authenticated: Verified active user session — may still be KYC-pending.
/// - error: An error occurred during the login process.
enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

/// Possible KYC verification states mirroring the backend `verification_status` field.
enum VerificationStatus {
  unknown, // Haven't fetched yet
  pending, // Registered, documents not yet approved
  verified, // Admin approved — full platform access
  rejected, // Rejected by admin — must resubmit
}

/// Maps raw backend string values to our typed [VerificationStatus] enum.
VerificationStatus verificationStatusFromString(String? s) {
  switch (s) {
    case 'verified':
      return VerificationStatus.verified;
    case 'rejected':
      return VerificationStatus.rejected;
    case 'pending':
    default:
      return VerificationStatus.pending;
  }
}

/// Immutable state container holding the current [AuthStatus], optional [errorMessage],
/// and the doctor's KYC [verificationStatus] used for routing decisions.
class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  /// KYC verification state — populated after login from the doctor profile endpoint.
  final VerificationStatus verificationStatus;

  /// True when identity login succeeded but doctor profile is not created yet.
  final bool requiresProfileCompletion;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.verificationStatus = VerificationStatus.unknown,
    this.requiresProfileCompletion = false,
  });

  /// Helper to create a cloned instance with updated fields.
  /// Use [clearErrorMessage] to clear a previous login error after success or a new attempt.
  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    VerificationStatus? verificationStatus,
    bool? requiresProfileCompletion,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      verificationStatus: verificationStatus ?? this.verificationStatus,
      requiresProfileCompletion:
          requiresProfileCompletion ?? this.requiresProfileCompletion,
    );
  }
}
