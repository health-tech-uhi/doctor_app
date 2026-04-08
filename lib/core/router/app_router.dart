import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/feature_flags.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/kyc/presentation/kyc_shell_screen.dart';
import '../../features/kyc/presentation/document_upload_screen.dart';
import '../../features/kyc/presentation/video_call_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/tabs/appointments_tab.dart';
import '../../features/dashboard/presentation/tabs/home_tab.dart';
import '../../features/dashboard/presentation/tabs/patients_tab.dart';
import '../../features/dashboard/presentation/tabs/profile_tab.dart';
import '../../features/doctor/presentation/complete_profile_screen.dart';
import '../../features/doctor/presentation/edit_profile_screen.dart';
import '../../features/appointments/domain/appointment.dart';
import '../../features/scribe/presentation/scribe_session_screen.dart';
import '../../features/scribe/presentation/summary_review_screen.dart';

/// Root navigator — full-screen routes (e.g. complete profile) stack above the tab shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Rebroadcasts AuthState changes to GoRouter so it re-evaluates redirects
/// automatically whenever authentication or verification status changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.verificationStatus != next.verificationStatus ||
          previous?.requiresProfileCompletion !=
              next.requiresProfileCompletion) {
        notifyListeners();
      }
    });
  }
}

/// Tab roots only — not nested `/profile/edit` so users can edit while KYC pending.
bool _isTabRootForKycGate(String location) {
  return location == '/home' ||
      location == '/schedule' ||
      location == '/patients' ||
      location == '/profile';
}

/// Centralized navigation map with auth + KYC + [StatefulShellRoute] tab stacks.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  final kycEnabled = ref.watch(kycFeatureEnabledProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      if (authState.status == AuthStatus.initial) return null;

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isVerified =
          authState.verificationStatus == VerificationStatus.verified;
      final needsProfileCompletion = authState.requiresProfileCompletion;

      final isOnAuth = location == '/login' || location == '/signup';
      final isOnKyc = location == '/kyc' || location.startsWith('/kyc/');
      final isOnCompleteProfile = location == '/complete-profile';

      if (!isAuthenticated && !isOnAuth) return '/login';

      if (isAuthenticated && isOnAuth) return '/home';

      if (isAuthenticated && needsProfileCompletion && !isOnCompleteProfile) {
        return '/complete-profile';
      }
      if (isAuthenticated && !needsProfileCompletion && isOnCompleteProfile) {
        return '/home';
      }

      if (!kycEnabled && isOnKyc) return '/home';

      if (kycEnabled && isAuthenticated) {
        if (!isVerified && !isOnKyc && _isTabRootForKycGate(location)) {
          return '/kyc';
        }
        if (isVerified && isOnKyc) return '/home';
      }

      if (location == '/dashboard') return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/kyc',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const KycShellScreen(),
      ),
      GoRoute(
        path: '/kyc/upload',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DocumentUploadScreen(),
      ),
      GoRoute(
        path: '/kyc/call',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VideoCallScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/scribe/session',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final appt = state.extra as Appointment?;
          if (appt == null) {
            return const Scaffold(
              body: Center(child: Text('Missing appointment for scribe')),
            );
          }
          return ScribeSessionScreen(appointment: appt);
        },
      ),
      GoRoute(
        path: '/scribe/review',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as ScribeSummaryReviewArgs?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Missing consultation summary')),
            );
          }
          return SummaryReviewScreen(args: args);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: HomeTab(
                    onCompleteProfileTap: () =>
                        GoRouter.of(context).go('/profile'),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AppointmentsTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patients',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const PatientsTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ProfileTab(),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'kyc',
                    builder: (context, state) => const KycShellScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
