import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/scribe_repository_impl.dart';
import '../domain/scribe_repository.dart';

final scribeRepositoryProvider = Provider<ScribeRepository>((ref) {
  return ScribeRepositoryImpl(ref.watch(dioClientProvider));
});
