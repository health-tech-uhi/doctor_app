import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paginated_result.dart';
import '../../../core/network/dio_client.dart';
import '../domain/appointment.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(dioClientProvider));
});

class AppointmentsRepository {
  AppointmentsRepository(this._dio);

  final Dio _dio;

  /// GET /api/appointments — list for current user (doctor or patient).
  Future<PaginatedResult<Appointment>> list({
    int page = 1,
    int perPage = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/appointments',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = response.data;
    if (data == null) {
      return PaginatedResult(
        items: const [],
        metadata: PaginationMetadata(
          totalCount: 0,
          page: page,
          perPage: perPage,
          totalPages: 0,
        ),
      );
    }
    return PaginatedResult.fromJson(data, Appointment.fromJson);
  }
}
