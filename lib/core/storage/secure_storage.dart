import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

class SecureStorage {
  final _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(
      usesDataProtectionKeychain: false,
    ),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static String? _memoryAccessToken;
  static String? _memoryRefreshToken;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    // Keep an in-memory copy so immediate follow-up requests after login
    // don't depend on keychain availability timing.
    _memoryAccessToken = accessToken;
    _memoryRefreshToken = refreshToken;
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } on PlatformException catch (e) {
      if (e.code == '-34018' || e.code == 'errSecMissingEntitlement' || kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, accessToken);
        await prefs.setString(_refreshTokenKey, refreshToken);
      } else {
        rethrow;
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (_memoryAccessToken != null) return _memoryAccessToken;
    try {
      final value = await _storage.read(key: _accessTokenKey);
      if (value != null) _memoryAccessToken = value;
      return value;
    } on PlatformException catch (e) {
      if (e.code == '-34018' || e.code == 'errSecMissingEntitlement' || kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getString(_accessTokenKey);
        if (value != null) _memoryAccessToken = value;
        return value;
      } else {
        rethrow;
      }
    }
  }

  Future<String?> getRefreshToken() async {
    if (_memoryRefreshToken != null) return _memoryRefreshToken;
    try {
      final value = await _storage.read(key: _refreshTokenKey);
      if (value != null) _memoryRefreshToken = value;
      return value;
    } on PlatformException catch (e) {
      if (e.code == '-34018' || e.code == 'errSecMissingEntitlement' || kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getString(_refreshTokenKey);
        if (value != null) _memoryRefreshToken = value;
        return value;
      } else {
        rethrow;
      }
    }
  }

  Future<void> clearTokens() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    }
  }
}
