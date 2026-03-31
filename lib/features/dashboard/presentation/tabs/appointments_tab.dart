import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/feedback/app_status_panel.dart';
import '../../../appointments/domain/appointment.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../logic/schedule_filters.dart';

/// Schedule tab — lists from GET /api/appointments (today, upcoming, past).
class AppointmentsTab extends ConsumerStatefulWidget {
  const AppointmentsTab({super.key});

  @override
  ConsumerState<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends ConsumerState<AppointmentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appointmentsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(async),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(async, mode: _ScheduleMode.upcoming),
              _buildAppointmentList(async, mode: _ScheduleMode.today),
              _buildAppointmentList(async, mode: _ScheduleMode.past),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AsyncValue<List<Appointment>> async) {
    final upcoming = async.maybeWhen(
      data: (all) => appointmentsUpcoming(all, DateTime.now()).length,
      orElse: () => null,
    );
    final today = async.maybeWhen(
      data: (all) => appointmentsOnDay(all, DateTime.now()).length,
      orElse: () => null,
    );
    final sub = async.isLoading
        ? 'Loading…'
        : 'Upcoming: ${upcoming ?? '—'} · Today: ${today ?? '—'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.tealAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.tealAccent,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'Today'),
          Tab(text: 'Past'),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(
    AsyncValue<List<Appointment>> async, {
    required _ScheduleMode mode,
  }) {
    return RefreshIndicator(
      color: Colors.tealAccent,
      onRefresh: () async {
        ref.invalidate(appointmentsListProvider);
        await ref.read(appointmentsListProvider.future);
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppStatusPanel(
                compact: true,
                icon: Icons.cloud_off_rounded,
                title: 'Couldn\'t load schedule',
                message: 'Pull to try again.',
              ),
            ),
          ],
        ),
        data: (all) {
          final now = DateTime.now();
          final items = switch (mode) {
            _ScheduleMode.upcoming => appointmentsUpcoming(all, now),
            _ScheduleMode.today => appointmentsOnDay(all, now),
            _ScheduleMode.past => appointmentsPast(all, now),
          };
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppStatusPanel(
                    compact: true,
                    icon: Icons.calendar_today_outlined,
                    iconSize: 44,
                    title: 'No appointments in this view',
                    message: _emptyMessage(mode),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            itemCount: items.length,
            itemBuilder: (context, i) => _buildCard(items[i], mode: mode),
          );
        },
      ),
    );
  }

  String _emptyMessage(_ScheduleMode mode) {
    return switch (mode) {
      _ScheduleMode.upcoming =>
        'No future appointments. Bookings from patients will appear here.',
      _ScheduleMode.today => 'You have no appointments scheduled for today.',
      _ScheduleMode.past => 'No past appointments in your history yet.',
    };
  }

  Widget _buildCard(Appointment appt, {required _ScheduleMode mode}) {
    final isPast = mode == _ScheduleMode.past;
    final dt = appt.requestedDatetime;
    final day = DateFormat('d').format(dt);
    final month = DateFormat('MMM').format(dt);
    final timeStr = DateFormat('h:mm a').format(dt);

    final s = appt.normalizedStatus;
    final statusColor = switch (s) {
      'accepted' => Colors.tealAccent,
      'requested' => Colors.amberAccent,
      'completed' => Colors.white54,
      'cancelled' => Colors.redAccent,
      'rejected' => Colors.redAccent,
      _ => Colors.white30,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isPast ? 0.02 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: isPast ? 0.04 : 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: isPast ? 0.04 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: isPast ? Colors.white30 : Colors.tealAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  month,
                  style: TextStyle(
                    color: isPast
                        ? Colors.white24
                        : Colors.tealAccent.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.displayPatientName,
                  style: TextStyle(
                    color: isPast ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  appt.displayReason,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: isPast ? Colors.white38 : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.tealAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appt.status.toUpperCase(),
                  style: TextStyle(
                    color: isPast ? Colors.white30 : statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
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

enum _ScheduleMode { upcoming, today, past }
