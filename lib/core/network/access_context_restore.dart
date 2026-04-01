import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

Future<void> saveTokensAfterContextSwitch({
  required Response<dynamic> response,
  required SecureStorage storage,
}) async {
  final data = response.data;
  if (data is! Map) return;
  final access = data['token'];
  if (access is! String) return;
  final refresh = data['refresh_token'] ?? data['refreshToken'];
  final String refreshToken;
  if (refresh is String) {
    refreshToken = refresh;
  } else {
    final existing = await storage.getRefreshToken();
    if (existing == null) return;
    refreshToken = existing;
  }
  await storage.saveTokens(accessToken: access, refreshToken: refreshToken);
}

/// Binds JWT to the doctor access-control profile (`profile_id` + `role` claims).
Future<void> restoreDoctorJwtProfile({
  required Dio plainDio,
  required SecureStorage storage,
}) async {
  final token = await storage.getAccessToken();
  if (token == null) return;
  final headers = {'Authorization': 'Bearer $token'};
  try {
    final profileRes = await plainDio.get<Map<String, dynamic>>(
      '/api/doctors/profile',
      options: Options(headers: headers),
    );
    final data = profileRes.data;
    if (data == null) return;
    final rawId = data['profile_id'];
    if (rawId == null) return;
    final switchRes = await plainDio.post<Map<String, dynamic>>(
      '/api/auth/switch-context',
      data: {'profile_id': rawId.toString()},
      options: Options(headers: headers),
    );
    await saveTokensAfterContextSwitch(response: switchRes, storage: storage);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return;
    rethrow;
  }
}
