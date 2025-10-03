import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../core/config/api_config.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({Dio? dio, TokenProvider? tokenProvider, String? baseUrl})
    : _tokenProvider = tokenProvider,
      _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? ApiConfig.baseUrl)) {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final provider = _tokenProvider;
          if (provider != null && options.headers['Authorization'] == null) {
            final token = await provider();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  final Dio _dio;
  final TokenProvider? _tokenProvider;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {Object? data}) {
    return _dio.delete<T>(path, data: data);
  }
}
