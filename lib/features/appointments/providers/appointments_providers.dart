import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/appointments_repository.dart';
import '../domain/appointment.dart';

/// Cached list for dashboard (refetch via [refreshAppointments]).
final appointmentsListProvider = FutureProvider.autoDispose<List<Appointment>>((
  ref,
) async {
  final page = await ref
      .watch(appointmentsRepositoryProvider)
      .list(page: 1, perPage: 100);
  return page.items;
});

void refreshAppointments(Ref ref) {
  ref.invalidate(appointmentsListProvider);
}
