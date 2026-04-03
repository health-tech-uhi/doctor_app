/// Matches `PaginatedResponse<T>` from health-platform `libs/common` (JSON snake_case).
class PaginationMetadata {
  PaginationMetadata({
    required this.totalCount,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  final int totalCount;
  final int page;
  final int perPage;
  final int totalPages;

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.parse(v.toString());
    return PaginationMetadata(
      totalCount: asInt(json['total_count']),
      page: asInt(json['page']),
      perPage: asInt(json['per_page']),
      totalPages: asInt(json['total_pages']),
    );
  }
}

class PaginatedResult<T> {
  PaginatedResult({required this.items, required this.metadata});

  final List<T> items;
  final PaginationMetadata metadata;

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return PaginatedResult(
      items: raw.map((e) => itemFromJson(e as Map<String, dynamic>)).toList(),
      metadata: PaginationMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
    );
  }
}
