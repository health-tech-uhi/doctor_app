import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' hide Appointment;

import '../../../../core/theme/doctor_theme.dart';
import '../../domain/appointment.dart';

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getAppointment(index).requestedDatetime;
  }

  @override
  DateTime getEndTime(int index) {
    return _getAppointment(index).requestedDatetime.add(const Duration(minutes: 30));
  }

  @override
  String getSubject(int index) {
    final appt = _getAppointment(index);
    return '${appt.displayPatientName} - ${appt.displayReason}';
  }

  @override
  Color getColor(int index) {
    final status = _getAppointment(index).normalizedStatus;
    if (status == 'accepted') return DoctorTheme.accentCyan;
    if (status == 'requested') return DoctorTheme.accentAmber;
    if (status == 'cancelled') return const Color(0xFFFF6B6B);
    return DoctorTheme.textTertiary;
  }

  Appointment _getAppointment(int index) => appointments![index] as Appointment;
}
