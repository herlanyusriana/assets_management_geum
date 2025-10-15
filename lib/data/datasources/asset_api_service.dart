import "package:dio/dio.dart";

import '../../domain/models/asset_status.dart';
import 'api_client.dart';

class AssetApiService {
  AssetApiService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await _client.get<Map<String, dynamic>>('/dashboard');
    return _unwrapResponse(response);
  }

  Future<List<dynamic>> fetchAssets({
    String? categoryId,
    AssetStatus status = AssetStatus.all,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (categoryId != null && categoryId.isNotEmpty) {
      query['asset_category_id'] = categoryId;
    }
    if (status != AssetStatus.all) {
      query['status'] = status.apiValue;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _client.get<Map<String, dynamic>>(
      '/assets',
      queryParameters: query.isEmpty ? null : query,
    );

    final data = _unwrapResponse(response);
    final assets = data['data'];
    if (assets is List) {
      return assets;
    }
    if (assets is Map && assets.values.every((value) => value is Map)) {
      return (assets.values).cast<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>?> fetchAssetByCode(String code) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/assets/code/$code',
    );
    final data = _unwrapResponse(response);
    return data['data'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> createAsset(dynamic payload) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/assets',
      data: payload,
    );
    final data = _unwrapResponse(response);
    return data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateAsset(String id, dynamic payload) async {
    Response<Map<String, dynamic>> response;
    if (payload is FormData) {
      payload.fields.removeWhere((entry) => entry.key == '_method');
      payload.fields.add(const MapEntry('_method', 'PUT'));

      response = await _client.post<Map<String, dynamic>>(
        '/assets/$id',
        data: payload,
      );
    } else {
      response = await _client.put<Map<String, dynamic>>(
        '/assets/$id',
        data: payload,
      );
    }
    final data = _unwrapResponse(response);
    return data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteAsset(String id) async {
    await _client.delete('/assets/$id');
  }

  Future<Response<List<int>>> downloadAssetReport(String format) {
    return _client.download(
      '/reports/assets/export',
      queryParameters: {'format': format},
    );
  }

  Map<String, dynamic> _unwrapResponse(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data;
    if (data == null) {
      return <String, dynamic>{};
    }
    if (data.containsKey('message') && data.length == 1) {
      throw DioException.badResponse(
        statusCode: response.statusCode ?? 500,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    return data;
  }
}
