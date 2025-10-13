import 'dart:io';
import "dart:math" as math;

import "package:flutter_bloc/flutter_bloc.dart";

import '../../../data/repositories/asset_repository.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/asset.dart';
import '../../../domain/models/asset_activity.dart';
import '../../../domain/models/asset_export_format.dart';
import '../../../domain/models/asset_report_file.dart';
import '../../../domain/models/asset_status.dart';
import '../../../domain/models/maintenance_entry.dart';
import "asset_state.dart";

class AssetCubit extends Cubit<AssetState> {
  AssetCubit(this._repository) : super(const AssetState());

  final AssetRepository _repository;
  static const int _pageSize = 6;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _repository.init();
      final totalAssets = await _repository.getTotalAssetCount();
      final criticalAssets = await _repository.getCriticalAssetCount();
      final categories = await _repository.getCategoriesWithStats();
      final assets = await _repository.getAssets();
      final users = await _repository.getAssignableUsers();

      emit(
        state.copyWith(
          isLoading: false,
          categories: categories,
          assets: assets,
          users: users,
          recentActivities: const [],
          totalAssets: totalAssets,
          criticalAssets: criticalAssets,
          successMessage: null,
          errorMessage: null,
        ),
      );
      _applyFilters(resetVisibleCount: true);
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  void selectCategory(String? categoryId) {
    emit(
      state.copyWith(
        selectedCategoryId: categoryId,
        statusFilter: AssetStatus.all,
        searchQuery: '',
      ),
    );
    _applyFilters(resetVisibleCount: true);
  }

  void setStatusFilter(AssetStatus status) {
    emit(state.copyWith(statusFilter: status));
    _applyFilters(resetVisibleCount: true);
  }

  void setSearchQuery(String query, {bool retainCategory = false}) {
    final trimmed = query.trim();
    final shouldClearCategory =
        !retainCategory &&
        trimmed.isNotEmpty &&
        state.selectedCategoryId != null;
    emit(
      state.copyWith(
        searchQuery: query,
        selectedCategoryId: shouldClearCategory
            ? null
            : state.selectedCategoryId,
      ),
    );
    _applyFilters(resetVisibleCount: true);
  }

  void clearCategorySelection({bool resetStatus = false}) {
    emit(
      state.copyWith(
        selectedCategoryId: null,
        statusFilter: resetStatus ? AssetStatus.all : state.statusFilter,
        searchQuery: state.searchQuery,
      ),
    );
    _applyFilters(resetVisibleCount: true);
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> addAsset(
    Asset asset, {
    AssetActivity? activity,
    File? photo,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.addAsset(asset, activity: activity, photo: photo);

      await initialize();
      emit(state.copyWith(successMessage: 'Asset added successfully'));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> updateAsset(
    Asset asset, {
    List<MaintenanceEntry>? maintenance,
    File? photo,
    bool removePhoto = false,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final updated = maintenance == null
          ? asset
          : asset.copyWith(maintenanceHistory: maintenance);
      await _repository.updateAsset(
        updated,
        photo: photo,
        removePhoto: removePhoto,
      );
      await initialize();
      emit(state.copyWith(successMessage: 'Asset updated'));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> deleteAsset(String id) async {
    emit(state.copyWith(isLoading: true, successMessage: null, errorMessage: null));
    try {
      await _repository.deleteAsset(id);
      final remainingAssets =
          state.assets.where((asset) => asset.id != id).toList();

      emit(
        state.copyWith(
          isLoading: false,
          assets: remainingAssets,
          totalAssets: state.totalAssets > 0 ? state.totalAssets - 1 : 0,
          successMessage: 'Asset deleted',
        ),
      );
      _applyFilters(resetVisibleCount: true);
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<Asset?> findAssetByCode(String code) async {
    try {
      return await _repository.getAssetByCode(code);
    } catch (_) {
      return null;
    }
  }

  void dismissMessage() {
    emit(state.copyWith(successMessage: null, errorMessage: null));
  }

  void loadMoreFilteredAssets() {
    if (state.filteredAssets.isEmpty) return;
    final newCount = state.visibleFilteredCount + _pageSize;
    final capped = newCount >= state.filteredAssets.length
        ? state.filteredAssets.length
        : newCount;
    emit(
      state.copyWith(
        visibleFilteredCount: capped,
        visibleFilteredAssets: state.filteredAssets.take(capped).toList(),
      ),
    );
  }

  Future<AssetReportFile> exportAssets(AssetExportFormat format) {
    return _repository.exportAssets(format);
  }

  List<AppUser> get assignableUsers => state.users;

  void _applyFilters({bool resetVisibleCount = false}) {
    final selectedCategory = state.selectedCategoryId;
    final query = state.searchQuery.trim().toLowerCase();
    final status = state.statusFilter;

    final filtered = state.assets.where((asset) {
      if (selectedCategory != null && asset.categoryId != selectedCategory) {
        return false;
      }
      if (status != AssetStatus.all && asset.status != status) {
        return false;
      }
      if (query.isNotEmpty) {
        final fields = <String?>[
          asset.name,
          asset.barcode,
          asset.serialNumber,
          asset.department,
          asset.assignedTo,
          asset.brand,
          asset.model,
        ];
        final matchQuery = fields.any((text) {
          if (text == null || text.trim().isEmpty) return false;
          return text.toLowerCase().contains(query);
        });
        if (!matchQuery) return false;
      }
      return true;
    }).toList();

    final targetCount = filtered.isEmpty
        ? 0
        : (resetVisibleCount || state.visibleFilteredCount == 0
              ? _pageSize
              : state.visibleFilteredCount);
    final capped = filtered.isEmpty
        ? 0
        : math.min(filtered.length, targetCount);

    emit(
      state.copyWith(
        filteredAssets: filtered,
        visibleFilteredCount: capped,
        visibleFilteredAssets: filtered.take(capped).toList(),
      ),
    );
  }
}
