import 'package:dio/dio.dart';

import 'api_client.dart';

class AuthApiService {
  AuthApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    if (data == null || data['token'] == null) {
      throw DioException.badResponse(
        statusCode: response.statusCode ?? 500,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.get<Map<String, dynamic>>('/me');
    return response.data ?? <String, dynamic>{};
  }

  Future<void> logout() async {
    await _client.post('/auth/logout');
  }
}
