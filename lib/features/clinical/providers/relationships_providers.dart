import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/relationships_repository.dart';
import '../domain/care_relationship.dart';

final relationshipsListProvider =
    FutureProvider.autoDispose<List<CareRelationship>>((ref) async {
  final page = await ref.watch(relationshipsRepositoryProvider).list(
        page: 1,
        perPage: 100,
      );
  return page.items;
});

void refreshRelationships(Ref ref) {
  ref.invalidate(relationshipsListProvider);
}
