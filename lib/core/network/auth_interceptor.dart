import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _refreshDio;
  /// Main app client — used to replay the failed request after a successful refresh.
  final Dio _mainDio;

  AuthInterceptor(this._secureStorage, this._refreshDio, this._mainDio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.uri.path;
    // Avoid refresh loops if the refresh call itself failed with 401.
    if (path.endsWith('/api/auth/refresh')) {
      await _handleLogout();
      return handler.next(err);
    }

    // Only one automatic replay after refresh — prevents infinite loops.
    if (err.requestOptions.extra['_auth_retry'] == true) {
      await _handleLogout();
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken != null) {
        try {
          // Backend contract expects snake_case request/response fields.
          // Keep legacy fallbacks for compatibility with older payloads.
          final response = await _refreshDio.post(
            '/api/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data as Map<String, dynamic>;
            final newAccessToken = data['token'] ?? data['accessToken'];
            final newRefreshToken = data['refresh_token'] ?? data['refreshToken'];

            if (newAccessToken != null && newRefreshToken != null) {
              await _secureStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              final retryOptions = err.requestOptions.copyWith(
                extra: {
                  ...err.requestOptions.extra,
                  '_auth_retry': true,
                },
              );
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              // Replay on the main client so base URL, adapters, and interceptors match.
              final retryResponse = await _mainDio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          // Refresh failed
          await _handleLogout();
        }
      } else {
        // No refresh token found
        await _handleLogout();
      }
    }

    // If not handled or refresh failed, propagate the error
    handler.next(err);
  }

  Future<void> _handleLogout() async {
    await _secureStorage.clearTokens();
    // Trigger redirect to login
    // e.g., using ref.read(routerProvider).go('/login') handled properly in actual implementation
    print('Tokens cleared. Triggering redirect to login.');
  }
}
