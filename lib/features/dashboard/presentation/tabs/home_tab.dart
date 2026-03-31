import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/feedback/app_snack_bar.dart';
import '../../../../core/ui/feedback/app_status_panel.dart';
import '../../../appointments/domain/appointment.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../clinical/domain/care_relationship.dart';
import '../../../clinical/providers/relationships_providers.dart';
import '../../../doctor/data/doctor_repository.dart';
import '../../../doctor/providers/doctor_providers.dart';
import '../../logic/schedule_filters.dart';

/// Home tab — greeting, stats from live APIs, and today’s appointments.
class HomeTab extends ConsumerWidget {
  final VoidCallback? onCompleteProfileTap;

  const HomeTab({super.key, this.onCompleteProfileTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState.requiresProfileCompletion) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildMissingProfileCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: AppStatusPanel(
                compact: true,
                icon: Icons.event_note_outlined,
                title: 'No schedule yet',
                message:
                    'Complete your doctor profile to load appointments from the server.',
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      );
    }

    final profileAsync = ref.watch(doctorProfileProvider);
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final relationshipsAsync = ref.watch(relationshipsListProvider);

    return RefreshIndicator(
      color: Colors.tealAccent,
      onRefresh: () async {
        ref.invalidate(appointmentsListProvider);
        ref.invalidate(relationshipsListProvider);
        await ref.read(appointmentsListProvider.future);
        await ref.read(relationshipsListProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: profileAsync.when(
              loading: () => _buildHeaderSkeleton(),
              error: (error, _) {
                if (error is DoctorProfileNotFoundException) {
                  return _buildMissingProfileCard();
                }
                return _buildHeader(context, 'Doctor');
              },
              data: (profile) {
                final firstName = profile.fullName.split(' ').first;
                return _buildHeader(context, firstName);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _buildStatsRow(
              appointmentsAsync,
              relationshipsAsync,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSectionTitle('Today\'s schedule', context),
          ),
          ..._buildTodayAppointmentSlivers(context, appointmentsAsync),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  List<Widget> _buildTodayAppointmentSlivers(
    BuildContext context,
    AsyncValue<List<Appointment>> appointmentsAsync,
  ) {
    final now = DateTime.now();
    return appointmentsAsync.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator())),
        ),
      ],
      error: (e, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppStatusPanel(
              compact: true,
              icon: Icons.cloud_off_outlined,
              title: 'Couldn\'t load appointments',
              message:
                  'Pull to refresh or open Schedule for more details.',
            ),
          ),
        ),
      ],
      data: (all) {
        final today = appointmentsOnDay(all, now);
        if (today.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AppStatusPanel(
                  compact: true,
                  icon: Icons.event_available_outlined,
                  title: 'Nothing scheduled today',
                  message:
                      'When patients book with you, their visits will show up here.',
                ),
              ),
            ),
          ];
        }
        return [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildAppointmentCard(today[i]),
              childCount: today.length,
            ),
          ),
        ];
      },
    );
  }

  Widget _buildHeader(BuildContext context, String firstName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: const EdgeInsets.only(
        top: 56,
        left: 24,
        right: 24,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(color: Colors.white60, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              AppSnackBar.show(
                context,
                'Notification inbox will use GET /api/auth/notifications when enabled.',
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              padding: const EdgeInsets.all(10),
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Colors.white70, size: 22),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 56, 24, 8),
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildMissingProfileCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 56, 24, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.tealAccent.withValues(alpha: 0.10),
            Colors.blueAccent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.tealAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your doctor profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add your specialization, fee, and license details to finish onboarding.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: onCompleteProfileTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Complete profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<Appointment>> appointmentsAsync,
    AsyncValue<List<CareRelationship>> relationshipsAsync,
  ) {
    final now = DateTime.now();
    final todayCount = appointmentsAsync.maybeWhen(
      data: (all) => appointmentsOnDay(all, now).length,
      orElse: () => null,
    );
    final upcomingCount = appointmentsAsync.maybeWhen(
      data: (all) => appointmentsUpcoming(all, now).length,
      orElse: () => null,
    );
    final pendingCount = appointmentsAsync.maybeWhen(
      data: (all) =>
          all.where((a) => a.normalizedStatus == 'requested').length,
      orElse: () => null,
    );
    final patientsCount = relationshipsAsync.maybeWhen(
      data: (all) => all.length,
      orElse: () => null,
    );

    String fmt(int? v) => v == null ? '—' : '$v';

    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        children: [
          _statCard(
            label: 'Today',
            value: fmt(todayCount),
            unit: 'Appointments',
            icon: Icons.event_available_rounded,
            color: Colors.tealAccent,
          ),
          _statCard(
            label: 'Upcoming',
            value: fmt(upcomingCount),
            unit: 'Future slots',
            icon: Icons.upcoming_rounded,
            color: Colors.amberAccent,
          ),
          _statCard(
            label: 'Pending',
            value: fmt(pendingCount),
            unit: 'Awaiting response',
            icon: Icons.pending_actions_rounded,
            color: Colors.lightBlueAccent,
          ),
          _statCard(
            label: 'Patients',
            value: fmt(patientsCount),
            unit: 'Care relationships',
            icon: Icons.people_alt_rounded,
            color: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/schedule'),
            child: const Text('View all'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    final s = appt.normalizedStatus;
    final statusColor = switch (s) {
      'accepted' => Colors.tealAccent,
      'requested' => Colors.amberAccent,
      'completed' => Colors.white54,
      'cancelled' => Colors.redAccent,
      'rejected' => Colors.redAccent,
      _ => Colors.white30,
    };

    final timeStr = DateFormat('h:mm a').format(appt.requestedDatetime);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueGrey.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                initialsFromName(appt.displayPatientName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.displayPatientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appt.displayReason,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appt.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
