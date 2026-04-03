import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/doctor_theme.dart';
import '../../../../core/ui/glass/aurora_background.dart';
import '../../../../core/ui/glass/glass_card.dart';
import '../../../../core/ui/glass/glass_icon_button.dart';
import '../../../../core/ui/glass/gradient_button.dart';
import '../../../appointments/domain/appointment.dart';
import '../../../appointments/providers/appointments_providers.dart';
import 'package:doctor_app/features/auth/providers/auth_provider.dart';
import '../../../clinical/domain/care_relationship.dart';
import '../../../clinical/providers/relationships_providers.dart';
import '../../../doctor/providers/doctor_providers.dart';
import '../../logic/schedule_filters.dart';

class HomeTab extends ConsumerWidget {
  final VoidCallback? onCompleteProfileTap;

  const HomeTab({super.key, this.onCompleteProfileTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBackground,
      body: AuroraBackground(
        child: RefreshIndicator(
          color: DoctorTheme.accentCyan,
          backgroundColor: DoctorTheme.surfaceElevated,
          onRefresh: () async {
            ref.invalidate(appointmentsListProvider);
            ref.invalidate(relationshipsListProvider);
            await ref.read(appointmentsListProvider.future);
            await ref.read(relationshipsListProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (authState.requiresProfileCompletion)
                SliverToBoxAdapter(child: _buildMissingProfileCard())
              else
                SliverToBoxAdapter(
                  child: ref
                      .watch(doctorProfileProvider)
                      .when(
                        loading: () => const SizedBox(height: 120),
                        error: (error, _) => _buildHeader(context, 'Doctor'),
                        data: (p) =>
                            _buildHeader(context, p.fullName.split(' ').first),
                      ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: _buildStatsGrid(
                    ref.watch(appointmentsListProvider),
                    ref.watch(relationshipsListProvider),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionTitle('Today\'s Schedule', context),
              ),
              ..._buildTodayAppointmentSlivers(
                context,
                ref.watch(appointmentsListProvider),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DoctorTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Dr. $firstName',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontSize: 28),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.notifications_none_rounded,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMissingProfileCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 12),
      child: GlassCard(
        color: DoctorTheme.accentCyan.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: DoctorTheme.accentCyan),
                const SizedBox(width: 12),
                Text(
                  'Complete Profile',
                  style: DoctorTheme.dark().textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your profile is 60% complete. Add your specialization to start receiving bookings.',
              style: TextStyle(color: DoctorTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Finish Setup',
              height: 48,
              onPressed: onCompleteProfileTap ?? () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    AsyncValue<List<Appointment>> appointmentsAsync,
    AsyncValue<List<CareRelationship>> relationshipsAsync,
  ) {
    final now = DateTime.now();
    final today = appointmentsAsync.maybeWhen(
      data: (all) => appointmentsOnDay(all, now).length,
      orElse: () => 0,
    );
    final upcoming = appointmentsAsync.maybeWhen(
      data: (all) => appointmentsUpcoming(all, now).length,
      orElse: () => 0,
    );
    final waiting = appointmentsAsync.maybeWhen(
      data: (all) => all.where((a) => a.normalizedStatus == 'requested').length,
      orElse: () => 0,
    );
    final patients = relationshipsAsync.maybeWhen(
      data: (all) => all.length,
      orElse: () => 0,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _statCard(
          'Today',
          today.toString(),
          Icons.calendar_today_rounded,
          DoctorTheme.accentCyan,
        ),
        _statCard(
          'Patients',
          patients.toString(),
          Icons.group_outlined,
          DoctorTheme.accentLavender,
        ),
        _statCard(
          'Upcoming',
          upcoming.toString(),
          Icons.bolt_rounded,
          DoctorTheme.accentAmber,
        ),
        _statCard(
          'Waiting',
          waiting.toString(),
          Icons.hourglass_empty_rounded,
          const Color(0xFFFF6B6B),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: DoctorTheme.textPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: DoctorTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/schedule'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'See All',
              style: TextStyle(
                color: DoctorTheme.accentCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTodayAppointmentSlivers(
    BuildContext context,
    AsyncValue<List<Appointment>> appointmentsAsync,
  ) {
    return appointmentsAsync.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ],
      error: (e, _) => [
        const SliverToBoxAdapter(
          child: Center(child: Text('Connect to load schedule')),
        ),
      ],
      data: (all) {
        final today = appointmentsOnDay(all, DateTime.now());
        if (today.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: DoctorTheme.textTertiary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Rest day — No appointments',
                        style: TextStyle(color: DoctorTheme.textTertiary),
                      ),
                    ],
                  ),
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

  Widget _buildAppointmentCard(Appointment appt) {
    final status = appt.normalizedStatus;
    final color = status == 'accepted'
        ? DoctorTheme.accentCyan
        : status == 'requested'
        ? DoctorTheme.accentAmber
        : DoctorTheme.textTertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(appt.displayPatientName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.displayPatientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: DoctorTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appt.displayReason,
                      style: const TextStyle(
                        color: DoctorTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(appt.requestedDatetime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DoctorTheme.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: DoctorTheme.accentCyan.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: DoctorTheme.glassStroke),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: DoctorTheme.accentCyan,
          ),
        ),
      ),
    );
  }
}
