import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' hide Appointment;
import 'package:syncfusion_flutter_core/theme.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/doctor_theme.dart';
import '../../../../core/ui/glass/aurora_background.dart';
import '../../../../core/ui/glass/glass_icon_button.dart';
import '../../../../core/ui/glass/glass_card.dart';
import '../../../appointments/domain/appointment.dart';
import '../../../appointments/presentation/widgets/pending_appointment_actions.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../appointments/presentation/calendar/appointment_data_source.dart';
import '../../../appointments/presentation/calendar/teams_calendar_picker.dart';

class AppointmentsTab extends ConsumerStatefulWidget {
  const AppointmentsTab({super.key});

  @override
  ConsumerState<AppointmentsTab> createState() => _AppointmentsTabState();
}

enum _ScheduleSegment { calendar, pending }

class _AppointmentsTabState extends ConsumerState<AppointmentsTab> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _currentView = CalendarView.day;
  _ScheduleSegment _segment = _ScheduleSegment.calendar;

  @override
  void initState() {
    super.initState();
    _calendarController.view = _currentView;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appointmentsListProvider);

    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBackground,
      body: AuroraBackground(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) =>
                    const Center(child: Text('Connect to load schedule')),
                data: (appointments) {
                  if (_segment == _ScheduleSegment.calendar) {
                    final accepted = appointments
                        .where((a) => a.normalizedStatus == 'accepted')
                        .toList();
                    return _buildCalendar(accepted);
                  } else {
                    final pending = appointments
                        .where((a) => a.normalizedStatus == 'requested')
                        .toList();
                    return _buildPendingList(pending);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule',
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage appointments and availability',
                      style: TextStyle(
                        color: DoctorTheme.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDateSelector(),
              const SizedBox(width: 12),
              GlassIconButton(
                icon: Icons.today_rounded,
                onPressed: () {
                  setState(() {
                    _calendarController.displayDate = DateTime.now();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSegmentSwitcher(),
          if (_segment == _ScheduleSegment.calendar) ...[
            const SizedBox(height: 16),
            _buildViewSwitcher(),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentSwitcher() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DoctorTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorTheme.glassStroke),
      ),
      child: Row(
        children: [
          _segmentItem(
            'Calendar',
            _ScheduleSegment.calendar,
            Icons.calendar_today_rounded,
          ),
          _segmentItem(
            'Pending',
            _ScheduleSegment.pending,
            Icons.hourglass_empty_rounded,
          ),
        ],
      ),
    );
  }

  Widget _segmentItem(String label, _ScheduleSegment segment, IconData icon) {
    final isSelected = _segment == segment;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = segment),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? DoctorTheme.accentCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: DoctorTheme.accentCyan.withValues(alpha: 0.3),
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? DoctorTheme.accentCyan
                    : DoctorTheme.secondaryText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? DoctorTheme.accentCyan
                      : DoctorTheme.secondaryText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final displayDate = _calendarController.displayDate ?? DateTime.now();
    final label = DateFormat('MMMM yyyy').format(displayDate);

    return InkWell(
      onTap: () => _showCalendarPicker(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DoctorTheme.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DoctorTheme.glassStroke, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: DoctorTheme.accentCyan,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: DoctorTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: DoctorTheme.textPrimary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCalendarPicker() async {
    final initialDate = _calendarController.displayDate ?? DateTime.now();
    final DateTime? selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => TeamsCalendarPicker(initialDate: initialDate),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _calendarController.displayDate = selectedDate;
      });
    }
  }

  Widget _buildViewSwitcher() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DoctorTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorTheme.glassStroke),
      ),
      child: Row(
        children: [
          _viewItem('Day', CalendarView.day),
          _viewItem('Week', CalendarView.week),
          _viewItem('Work Week', CalendarView.workWeek),
        ],
      ),
    );
  }

  Widget _viewItem(String label, CalendarView view) {
    final isSelected = _currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentView = view);
          _calendarController.view = view;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? DoctorTheme.accentCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: DoctorTheme.accentCyan.withValues(alpha: 0.3),
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? DoctorTheme.accentCyan
                  : DoctorTheme.secondaryText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(List<Appointment> appointments) {
    return SfCalendarTheme(
      data: SfCalendarThemeData(
        backgroundColor: Colors.transparent,
        headerTextStyle: const TextStyle(
          color: DoctorTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        viewHeaderDateTextStyle: const TextStyle(
          color: DoctorTheme.textSecondary,
        ),
        viewHeaderDayTextStyle: const TextStyle(
          color: DoctorTheme.textTertiary,
        ),
        timeTextStyle: const TextStyle(color: DoctorTheme.textTertiary),
        todayHighlightColor: DoctorTheme.accentCyan,
        selectionBorderColor: DoctorTheme.accentCyan,
      ),
      child: SfCalendar(
        controller: _calendarController,
        view: _currentView,
        allowedViews: const [
          CalendarView.day,
          CalendarView.week,
          CalendarView.workWeek,
        ],
        allowViewNavigation: true,
        dataSource: AppointmentDataSource(appointments),
        firstDayOfWeek: 1, // Monday
        headerHeight: 0, // We use a custom header
        todayHighlightColor: DoctorTheme.accentCyan,
        showCurrentTimeIndicator: true,
        appointmentBuilder: _appointmentBuilder,
        viewHeaderHeight: 75,
        cellBorderColor: DoctorTheme.glassStroke.withValues(alpha: 0.15),
        selectionDecoration: BoxDecoration(
          color: DoctorTheme.accentCyan.withValues(alpha: 0.05),
          border: Border.all(
            color: DoctorTheme.accentCyan.withValues(alpha: 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        timeSlotViewSettings: const TimeSlotViewSettings(
          startHour: 8,
          endHour: 20,
          timeInterval: Duration(minutes: 30),
          timeFormat: 'hh:mm a',
          timeIntervalHeight: 120, // Increased for spacing
          timeRulerSize:
              91, // Wider ruler to achieve ~16dp additional left label breathing room
          timelineAppointmentHeight: 60,
          timeTextStyle: TextStyle(
            color: DoctorTheme.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: (details) {
          if (details.appointments != null &&
              details.appointments!.isNotEmpty) {
            final appt = details.appointments!.first as Appointment;
            _showAppointmentDetails(appt);
          }
        },
      ),
    );
  }

  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final appt = details.appointments.first as Appointment;
    final status = appt.normalizedStatus;
    final color = status == 'accepted'
        ? DoctorTheme.accentCyan
        : status == 'requested'
        ? DoctorTheme.accentAmber
        : status == 'cancelled'
        ? const Color(0xFFFF6B6B)
        : DoctorTheme.textTertiary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showDetails = constraints.maxHeight > 60;
        final isVerySmall = constraints.maxHeight < 40;

        return Padding(
          padding: const EdgeInsets.all(1.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 2 : 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    appt.displayPatientName,
                                    style: TextStyle(
                                      color: DoctorTheme.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: isVerySmall ? 14 : 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isVerySmall)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (showDetails) ...[
                              const SizedBox(height: 2),
                              Text(
                                appt.displayReason,
                                style: const TextStyle(
                                  color: DoctorTheme.secondaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAppointmentDetails(Appointment appt) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AppointmentDetailSheet(appointment: appt),
    );
  }

  Widget _buildPendingList(List<Appointment> pending) {
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 64,
              color: DoctorTheme.textTertiary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending requests',
              style: TextStyle(
                color: DoctorTheme.textTertiary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final appt = pending[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _showAppointmentDetails(appt),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DoctorTheme.accentAmber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DoctorTheme.accentAmber.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: DoctorTheme.accentAmber,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.displayPatientName,
                        style: const TextStyle(
                          color: DoctorTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM d, h:mm a',
                        ).format(appt.requestedDatetime),
                        style: const TextStyle(
                          color: DoctorTheme.accentAmber,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DoctorTheme.textTertiary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppointmentDetailSheet extends ConsumerWidget {
  const _AppointmentDetailSheet({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = appointment.normalizedStatus;
    final color = status == 'accepted'
        ? DoctorTheme.accentCyan
        : status == 'requested'
        ? DoctorTheme.accentAmber
        : status == 'cancelled'
        ? const Color(0xFFFF6B6B)
        : DoctorTheme.textTertiary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: DoctorTheme.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DoctorTheme.glassStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.displayPatientName,
                            style: const TextStyle(
                              color: DoctorTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'EEEE, MMMM d • hh:mm a',
                            ).format(appointment.requestedDatetime),
                            style: const TextStyle(
                              color: DoctorTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _statusChip(appointment.status, color),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _detailRow(
                    Icons.medical_services_outlined,
                    'Reason',
                    appointment.displayReason,
                  ),
                  const SizedBox(height: 16),
                  if (appointment.chiefComplaint != null)
                    _buildNotesSection(
                      Icons.notes_rounded,
                      'Notes',
                      appointment.chiefComplaint!,
                    ),
                  const SizedBox(height: 40),
                  if (status == 'requested')
                    PendingAppointmentActions(appointment: appointment)
                  else if (status == 'accepted') ...[
                    if (ref.watch(scribeFeatureEnabledProvider)) ...[
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/scribe/session', extra: appointment);
                        },
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Clinical scribe'),
                        style: FilledButton.styleFrom(
                          backgroundColor: DoctorTheme.accentCyan,
                          foregroundColor: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.videocam_rounded),
                      label: const Text('Start Consultation'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DoctorTheme.accentCyan,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DoctorTheme.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DoctorTheme.glassStroke),
          ),
          child: Icon(icon, size: 20, color: DoctorTheme.accentCyan),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: DoctorTheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: DoctorTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DoctorTheme.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DoctorTheme.glassStroke),
          ),
          child: Icon(icon, size: 20, color: DoctorTheme.accentCyan),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: DoctorTheme.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildEditButton(),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: DoctorTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        // Handle edit notes
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DoctorTheme.accentCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          children: [
            Icon(Icons.edit_rounded, size: 12, color: DoctorTheme.accentCyan),
            SizedBox(width: 4),
            Text(
              'Edit',
              style: TextStyle(
                color: DoctorTheme.accentCyan,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
