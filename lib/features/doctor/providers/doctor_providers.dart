import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor_profile.dart';
import '../../kyc/domain/kyc_document.dart';

/// Async provider that fetches and caches the authenticated doctor's profile.
/// Consuming widgets can use .when() to handle loading/error/data states.
final doctorProfileProvider = AsyncNotifierProvider<DoctorProfileNotifier, DoctorProfile>(
  DoctorProfileNotifier.new,
);

class DoctorProfileNotifier extends AsyncNotifier<DoctorProfile> {
  /// Filled by [AuthNotifier] **before** [ref.read(doctorProfileProvider.notifier)] so the
  /// first [build] cannot start a duplicate GET (Riverpod may invoke [build] as soon as the
  /// notifier is created, before [seedFromHydration] runs on the same call chain).
  static AsyncValue<DoctorProfile>? _pendingHydration;

  /// Call synchronously **before** [ref.read(doctorProfileProvider.notifier)] in auth hydration.
  static void preparePendingHydration(AsyncValue<DoctorProfile> value) {
    _pendingHydration = value;
  }

  static void clearPendingHydration() {
    _pendingHydration = null;
  }

  /// Called from [AuthNotifier] after login/session restore so we do not issue a
  /// second `GET /api/doctors/profile` when the dashboard first watches this provider.
  void seedFromHydration(AsyncValue<DoctorProfile> value) {
    state = value;
  }

  @override
  Future<DoctorProfile> build() async {
    final pending = _pendingHydration;
    if (pending != null) {
      _pendingHydration = null;
      state = pending;
      if (pending.hasValue) return pending.requireValue;
      if (pending.hasError) {
        final err = pending.error!;
        final st = pending.stackTrace ?? StackTrace.current;
        Error.throwWithStackTrace(err, st);
      }
    }

    // If auth already populated state via [seedFromHydration], do not fetch again.
    if (state.hasValue) return state.requireValue;
    if (state.hasError) {
      final err = state.error!;
      final st = state.stackTrace ?? StackTrace.current;
      Error.throwWithStackTrace(err, st);
    }
    // Use read — repository is a thin wrapper; watching it can refetch on unrelated churn.
    return ref.read(doctorRepositoryProvider).getProfile();
  }

  /// Manually refreshes the profile from the backend.
  /// Useful after signup or profile updates.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).getProfile(),
    );
  }
}

/// Async provider that fetches the current KYC verification status and all
/// submitted documents. Auto-refreshes when the doctor uploads a new file.
final kycStatusProvider = AsyncNotifierProvider<KycStatusNotifier, KycStatus>(
  KycStatusNotifier.new,
);

class KycStatusNotifier extends AsyncNotifier<KycStatus> {
  @override
  Future<KycStatus> build() async {
    final raw = await ref.read(doctorRepositoryProvider).getKycStatus();
    return KycStatus.fromJson(raw);
  }

  /// Refreshes KYC status — call this after uploading a document.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final raw = await ref.read(doctorRepositoryProvider).getKycStatus();
      return KycStatus.fromJson(raw);
    });
  }
}
