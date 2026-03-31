import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paginated_result.dart';
import '../../../core/network/dio_client.dart';
import '../domain/care_relationship.dart';

final relationshipsRepositoryProvider = Provider<RelationshipsRepository>((ref) {
  return RelationshipsRepository(ref.watch(dioClientProvider));
});

class RelationshipsRepository {
  RelationshipsRepository(this._dio);

  final Dio _dio;

  /// GET /api/records/relationships — care relationships for current user (doctor sees patients).
  Future<PaginatedResult<CareRelationship>> list({
    int page = 1,
    int perPage = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/records/relationships',
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
    return PaginatedResult.fromJson(data, CareRelationship.fromJson);
  }
}
