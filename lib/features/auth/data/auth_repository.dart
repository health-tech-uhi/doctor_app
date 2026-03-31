import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

/// Provider exposing the [AuthRepository] instance cleanly across the context.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});

/// Handles direct interactions with the backend API endpoints related to authentication
/// and securely interfaces with the internal storage mechanisms.
///
/// This app is **doctor-only**: login uses `/api/auth/login` and stored tokens are always
/// for the doctor flow. There is no `/api/auth/switch-context` (unlike the multi-role web BFF).
class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  /// Triggers signup OTP for an identifier that does not yet have an account.
  /// Backend: POST /api/auth/signup/otp/generate
  Future<void> generateOtp({
    required String identifier,
    required String channel, // "Email" | "Sms"
  }) async {
    await _dio.post('/api/auth/signup/otp/generate', data: {
      'identifier': identifier,
      'channel': channel,
    });
  }

  /// Verifies signup OTP before account creation proceeds.
  /// Backend: POST /api/auth/signup/otp/verify
  Future<void> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    await _dio.post('/api/auth/signup/otp/verify', data: {
      'identifier': identifier,
      'otp': otp,
    });
  }

  /// Hits the remote API passing credentials.
  /// Standardly accepts [identifier] (username/email/phone) and [password].
  Future<void> login(String identifier, String password) async {
    try {
      // Endpoint mapping directly to backend-for-frontend POST /api/auth/login
      final response = await _dio.post('/api/auth/login', data: {
        'identifier': identifier,
        'credential': password,
        'login_type': 'Password', // We explicitly use password-based login here
      });

      // Parse JSON token pairs out from standard response footprint
      final accessToken = response.data['token'];
      final refreshToken = response.data['refresh_token'];

      // Require tokens to commit safe login validation
      if (accessToken != null && refreshToken != null) {
        await _storage.saveTokens(
          accessToken: accessToken, 
          refreshToken: refreshToken,
        );
      } else {
        throw Exception('Invalid tokens received from server');
      }
    } catch (e) {
      // Re-throw standardized exception or parse interceptor Dio errors
      rethrow;
    }
  }

  /// Registers a new user account in the system.
  /// Backend: POST /api/auth/register
  Future<void> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    await _dio.post('/api/auth/register', data: {
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    });
  }

  /// Pings backend out of courtesy and drops tokens immediately protecting the local device state.
  Future<void> logout() async {
    try {
       // Fire-and-forget clear via /api/auth/logout mapping
      await _dio.post('/api/auth/logout');
    } catch (e) {
      // Ignored for UX handling. We clear Local tokens no matter the ping response!
    } finally {
      await _storage.clearTokens();
    }
  }
  
  /// Verifies presence of token locally. 
  /// NOTE: Only checks existence, token validity requires a full request dispatch.
  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
