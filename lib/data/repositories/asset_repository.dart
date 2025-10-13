import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/app_user.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/asset_activity.dart';
import '../../domain/models/asset_category.dart';
import '../../domain/models/asset_status.dart';
import '../../domain/models/asset_export_format.dart';
import '../../domain/models/asset_report_file.dart';
import '../../domain/models/maintenance_entry.dart';
import '../datasources/api_client.dart';
import '../datasources/asset_api_service.dart';
import '../datasources/user_api_service.dart';

class AssetRepository {
  AssetRepository({
    AssetApiService? apiService,
    UserApiService? userApiService,
    TokenProvider? tokenProvider,
  }) : _api =
           apiService ??
           AssetApiService(client: ApiClient(tokenProvider: tokenProvider)),
       _userApi =
           userApiService ??
           UserApiService(client: ApiClient(tokenProvider: tokenProvider));

  final AssetApiService _api;
  final UserApiService _userApi;

  bool _dashboardLoaded = false;
  bool _usersLoaded = false;
  int _totalAssets = 0;
  int _criticalAssets = 0;
  List<AssetCategory> _categories = const [];
  List<AppUser> _users = const [];

  Future<void> init() async {
    await Future.wait([
      _refreshDashboard(force: true),
      _ensureUsers(force: true),
    ]);
  }

  Future<void> _refreshDashboard({bool force = false}) async {
    if (_dashboardLoaded && !force) return;

    final data = await _api.fetchDashboard();
    final summary = (data['summary'] as Map?)?.cast<String, dynamic>();
    _totalAssets = _parseInt(summary?['total_assets'] ?? data['total_assets']);
    _criticalAssets = _parseInt(
      summary?['critical_assets'] ?? data['critical_assets'],
    );

    final categoriesData = (data['categories'] as List?) ?? const [];
    _categories = categoriesData
        .whereType<Map>()
        .map((raw) => AssetCategory.fromMap(raw.cast<String, dynamic>()))
        .toList();

    _dashboardLoaded = true;
  }

  Future<void> _ensureUsers({bool force = false}) async {
    if (_usersLoaded && !force) return;

    final payload = await _userApi.fetchUsers();
    _users = payload
        .whereType<Map>()
        .map((raw) => AppUser.fromMap(raw.cast<String, dynamic>()))
        .toList();
    _usersLoaded = true;
  }

  int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<List<AssetCategory>> getCategoriesWithStats() async {
    await _refreshDashboard();
    return _categories;
  }

  Future<List<AppUser>> getAssignableUsers() async {
    await _ensureUsers();
    return _users;
  }

  Future<List<Asset>> getAssets({
    String? categoryId,
    AssetStatus status = AssetStatus.all,
    String? query,
  }) async {
    final payload = await _api.fetchAssets(
      categoryId: categoryId,
      status: status,
      search: query,
    );

    return payload.whereType<Map>().map((raw) {
      final map = raw.cast<String, dynamic>();
      final maintenance =
          (map['maintenance_history'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) =>
                    MaintenanceEntry.fromMap(entry.cast<String, dynamic>()),
              )
              .toList() ??
          const [];
      return Asset.fromMap(map, maintenanceHistory: maintenance);
    }).toList();
  }

  Future<void> addAsset(
    Asset asset, {
    AssetActivity? activity,
    File? photo,
  }) async {
    final payload = _assetToPayload(asset);
    final formData = await _buildFormData(payload, photo: photo);
    await _api.createAsset(formData);
    _dashboardLoaded = false;
  }

  Future<void> updateAsset(
    Asset asset, {
    AssetActivity? activity,
    File? photo,
    bool removePhoto = false,
  }) async {
    final payload = _assetToPayload(asset);
    final formData = await _buildFormData(
      payload,
      photo: photo,
      removePhoto: removePhoto,
    );
    await _api.updateAsset(asset.id, formData);
    _dashboardLoaded = false;
  }

  Future<int> getTotalAssetCount() async {
    await _refreshDashboard();
    return _totalAssets;
  }

  Future<int> getCriticalAssetCount() async {
    await _refreshDashboard();
    return _criticalAssets;
  }

  Future<Map<String, int>> getStatusBreakdown(String categoryId) async {
    final assets = await getAssets(categoryId: categoryId);
    final breakdown = <String, int>{};
    for (final asset in assets) {
      breakdown.update(
        asset.status.name,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return breakdown;
  }

  Future<void> deleteAsset(String id) async {
    await _api.deleteAsset(id);
    _dashboardLoaded = false;
  }

  Future<Asset?> getAssetByCode(String code) async {
    final payload = await _api.fetchAssetByCode(code);
    if (payload == null) return null;
    final map = payload.cast<String, dynamic>();
    final maintenance =
        (map['maintenance_history'] as List?)
            ?.whereType<Map>()
            .map(
              (entry) =>
                  MaintenanceEntry.fromMap(entry.cast<String, dynamic>()),
            )
            .toList() ??
        const [];
    return Asset.fromMap(map, maintenanceHistory: maintenance);
  }

  Future<AssetReportFile> exportAssets(AssetExportFormat format) async {
    final response = await _api.downloadAssetReport(format.queryValue);
    final bytes = Uint8List.fromList(response.data ?? <int>[]);
    final disposition = response.headers.value('content-disposition') ?? '';
    final filename =
        _extractFilename(disposition) ??
        'assets-report.${format.recommendedExtension}';
    final mimeType =
        response.headers.value('content-type') ??
        (format == AssetExportFormat.pdf ? 'application/pdf' : 'text/csv');

    return AssetReportFile(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
  }

  Map<String, dynamic> _assetToPayload(Asset asset) {
    final payload = <String, dynamic>{
      'asset_code': asset.barcode,
      'barcode': asset.barcode,
      'name': asset.name,
      'asset_category_id': int.tryParse(asset.categoryId) ?? asset.categoryId,
      'serial_number': asset.serialNumber,
      'brand': asset.brand,
      'model': asset.model,
      'processor_name': asset.processorName,
      'ram_capacity': asset.ramCapacity,
      'storage_type': asset.storageType,
      'storage_brand': asset.storageBrand,
      'storage_capacity': asset.storageCapacity,
      'purchase_date': asset.purchaseDate?.toIso8601String(),
      'purchase_price': asset.purchasePrice,
      'warranty_expiry': asset.warrantyExpiry?.toIso8601String(),
      'status': asset.status.apiValue,
      'location': asset.location,
      'condition_notes': asset.notes,
      'department': asset.department,
      'custodian_name': asset.assignedTo,
      'current_custodian_id': asset.custodianId != null
          ? int.tryParse(asset.custodianId!) ?? asset.custodianId
          : null,
    };

    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    return payload;
  }

  Future<FormData> _buildFormData(
    Map<String, dynamic> payload, {
    File? photo,
    bool removePhoto = false,
  }) async {
    final map = Map<String, dynamic>.from(payload);
    if (removePhoto) {
      map['remove_asset_photo'] = '1';
    }

    final formData = FormData.fromMap(map);

    if (photo != null) {
      final fileName = p.basename(photo.path);
      formData.files.add(
        MapEntry(
          'asset_photo',
          await MultipartFile.fromFile(photo.path, filename: fileName),
        ),
      );
    }

    return formData;
  }

  String? _extractFilename(String disposition) {
    final utf8Match = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (utf8Match != null) {
      return Uri.decodeFull(utf8Match.group(1)!);
    }

    final quoted = RegExp(
      r'filename="([^\";]+)"',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (quoted != null) {
      return quoted.group(1);
    }

    final simple = RegExp(
      r'filename=([^;]+)',
      caseSensitive: false,
    ).firstMatch(disposition);
    return simple?.group(1);
  }
}
