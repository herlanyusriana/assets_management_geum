import 'package:shared_preferences/shared_preferences.dart';

import '../datasources/api_client.dart';
import '../datasources/auth_api_service.dart';

class AuthRepository {
  AuthRepository({AuthApiService? apiService})
    : _prefsFuture = SharedPreferences.getInstance(),
      _api =
          apiService ??
          AuthApiService(
            client: ApiClient(
              tokenProvider: () async {
                final prefs = await SharedPreferences.getInstance();
                return prefs.getString(_tokenKey);
              },
            ),
          );

  static const _tokenKey = 'auth_token';
  static const _displayNameKey = 'auth_display_name';
  static const _emailKey = 'auth_email';

  final Future<SharedPreferences> _prefsFuture;
  final AuthApiService _api;

  Future<String?> _getToken() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final profile = await _api.me();
      if (profile.isEmpty) {
        await logout();
        return false;
      }
      await _persistUser(
        token: token,
        email: (profile['email'] as String?) ?? '',
        displayName:
            (profile['name'] as String?) ?? (profile['email'] as String? ?? ''),
      );
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> _persistUser({
    required String token,
    required String email,
    required String displayName,
  }) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_displayNameKey, displayName);
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await _api.login(email: email, password: password);
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>?;
      await _persistUser(
        token: token,
        email: (user?['email'] as String?) ?? email,
        displayName: (user?['name'] as String?) ?? email.split('@').first,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Ignore network errors during logout.
    }

    final prefs = await _prefsFuture;
    await prefs.remove(_tokenKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_emailKey);
  }

  Future<String?> getDisplayName() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_displayNameKey);
  }

  Future<String?> getEmail() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_emailKey);
  }

  Future<String?> getToken() => _getToken();
}
