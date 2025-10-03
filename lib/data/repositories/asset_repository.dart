import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/app_user.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/asset_activity.dart';
import '../../domain/models/asset_category.dart';
import '../../domain/models/asset_status.dart';
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

    final activitiesData = (data['recent_activities'] as List?) ?? const [];

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

  AssetActivity? _mapActivity(Map<String, dynamic> map) {
    final asset = (map['asset'] as Map?)?.cast<String, dynamic>();
    if (asset == null) {
      return null;
    }
    final assetId = asset['id']?.toString() ?? '';
    final assignedAt = _parseDateTime(map['assigned_at']) ?? DateTime.now();
    final id = '_';
    final assignedTo = map['assigned_to'] as String?;
    final notes = map['notes'] as String?;
    final descriptionParts = <String>[];
    if (assignedTo != null && assignedTo.isNotEmpty) {
      descriptionParts.add('Assigned to ');
    }
    if (notes != null && notes.isNotEmpty) {
      descriptionParts.add(notes);
    }
    final description = descriptionParts.isEmpty
        ? 'Status: '
        : descriptionParts.join(' • ');

    return AssetActivity(
      id: id,
      assetId: assetId,
      title: asset['name'] as String? ?? 'Asset Update',
      description: description,
      timestamp: assignedAt,
      type: map['returned_at'] != null ? 'returned' : 'assigned',
    );
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

  Map<String, dynamic> _assetToPayload(Asset asset) {
    final payload = <String, dynamic>{
      'asset_code': asset.serialNumber,
      'name': asset.name,
      'asset_category_id': int.tryParse(asset.categoryId) ?? asset.categoryId,
      'serial_number': asset.serialNumber,
      'brand': asset.brand,
      'model': asset.model,
      'purchase_date': asset.purchaseDate?.toIso8601String(),
      'purchase_price': asset.purchasePrice,
      'warranty_expiry': asset.warrantyExpiry?.toIso8601String(),
      'status': asset.status.apiValue,
      'location': asset.location,
      'condition_notes': asset.notes,
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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
