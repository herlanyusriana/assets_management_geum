import "package:equatable/equatable.dart";

import '../../../domain/models/app_user.dart';
import '../../../domain/models/asset.dart';
import '../../../domain/models/asset_activity.dart';
import '../../../domain/models/asset_category.dart';
import '../../../domain/models/asset_status.dart';

class AssetState extends Equatable {
  const AssetState({
    this.isLoading = true,
    this.categories = const [],
    this.assets = const [],
    this.recentActivities = const [],
    this.filteredAssets = const [],
    this.visibleFilteredAssets = const [],
    this.visibleFilteredCount = 0,
    this.selectedCategoryId,
    this.statusFilter = AssetStatus.all,
    this.searchQuery = '',
    this.totalAssets = 0,
    this.criticalAssets = 0,
    this.users = const [],
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final List<AssetCategory> categories;
  final List<Asset> assets;
  final List<AssetActivity> recentActivities;
  final List<Asset> filteredAssets;
  final List<Asset> visibleFilteredAssets;
  final int visibleFilteredCount;
  final String? selectedCategoryId;
  final AssetStatus statusFilter;
  final String searchQuery;
  final int totalAssets;
  final int criticalAssets;
  final List<AppUser> users;
  final String? errorMessage;
  final String? successMessage;

  AssetState copyWith({
    bool? isLoading,
    List<AssetCategory>? categories,
    List<Asset>? assets,
    List<AssetActivity>? recentActivities,
    List<Asset>? filteredAssets,
    List<Asset>? visibleFilteredAssets,
    int? visibleFilteredCount,
    String? selectedCategoryId,
    AssetStatus? statusFilter,
    String? searchQuery,
    int? totalAssets,
    int? criticalAssets,
    List<AppUser>? users,
    String? errorMessage,
    String? successMessage,
  }) {
    return AssetState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      assets: assets ?? this.assets,
      recentActivities: recentActivities ?? this.recentActivities,
      filteredAssets: filteredAssets ?? this.filteredAssets,
      visibleFilteredAssets:
          visibleFilteredAssets ?? this.visibleFilteredAssets,
      visibleFilteredCount: visibleFilteredCount ?? this.visibleFilteredCount,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      totalAssets: totalAssets ?? this.totalAssets,
      criticalAssets: criticalAssets ?? this.criticalAssets,
      users: users ?? this.users,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        categories,
        assets,
        recentActivities,
        filteredAssets,
        visibleFilteredAssets,
        visibleFilteredCount,
        selectedCategoryId,
        statusFilter,
        searchQuery,
        totalAssets,
        criticalAssets,
        users,
        errorMessage,
        successMessage,
      ];
}
