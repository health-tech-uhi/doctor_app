import '../../appointments/domain/appointment.dart';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameCalendarDay(DateTime a, DateTime b) =>
    _startOfDay(a) == _startOfDay(b);

/// Appointments whose [requestedDatetime] falls on the given calendar day (local).
List<Appointment> appointmentsOnDay(List<Appointment> all, DateTime day) {
  final out = all
      .where((a) => sameCalendarDay(a.requestedDatetime, day))
      .toList();
  out.sort((a, b) => a.requestedDatetime.compareTo(b.requestedDatetime));
  return out;
}

/// Strictly after the end of [today] (local) — "future" days only.
List<Appointment> appointmentsUpcoming(List<Appointment> all, DateTime now) {
  final endOfToday = _startOfDay(now).add(const Duration(days: 1));
  final out = all
      .where((a) => !a.requestedDatetime.isBefore(endOfToday))
      .toList();
  out.sort((a, b) => a.requestedDatetime.compareTo(b.requestedDatetime));
  return out;
}

/// Before start of today (local).
List<Appointment> appointmentsPast(List<Appointment> all, DateTime now) {
  final startToday = _startOfDay(now);
  final out = all
      .where((a) => a.requestedDatetime.isBefore(startToday))
      .toList();
  out.sort((a, b) => b.requestedDatetime.compareTo(a.requestedDatetime));
  return out;
}

String initialsFromName(String? name) {
  final t = name?.trim() ?? '';
  if (t.isEmpty) return '?';
  final parts = t.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return t[0].toUpperCase();
}
