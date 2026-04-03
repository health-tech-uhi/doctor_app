import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

// Assuming base URL from health-platform .env where APP__PORT=3111
// Use the computer's local IP address so physical devices can connect
// String.fromEnvironment allows injecting at build time.
final baseUrlProvider = Provider<String>((ref) {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // Read from .env file loaded in main.dart
  return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3111';
});

final dioClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Add Auth Interceptor (adds token, refresh; retries on 401 using the same [dio]).
  dio.interceptors.add(AuthInterceptor(secureStorage, refreshDio, dio));

  // Add logging for debug mode
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj.toString()),
    ),
  );

  return dio;
});
