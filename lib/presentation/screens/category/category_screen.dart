import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import '../../../core/utils/icon_mapper.dart';
import '../../../domain/models/asset_category.dart';
import '../../../domain/models/asset_status.dart';
import '../../bloc/asset/asset_cubit.dart';
import '../../bloc/asset/asset_state.dart';
import '../../bloc/navigation/navigation_cubit.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/asset_tile.dart';
import '../add_asset/add_asset_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final AssetCategory category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final TextEditingController _searchController;
  late final AssetCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AssetCubit>();
    _searchController = TextEditingController(text: _cubit.state.searchQuery);
    _cubit.selectCategory(widget.category.id);
    _searchController.text = '';
  }

  @override
  void dispose() {
    _cubit.selectCategory(null);
    _cubit.setStatusFilter(AssetStatus.all);
    _cubit.setSearchQuery('', retainCategory: false);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationIndex = context.watch<NavigationCubit>().state;
    return BlocBuilder<AssetCubit, AssetState>(
      builder: (context, state) {
        final assets = state.visibleFilteredAssets;
        final hasMore =
            state.visibleFilteredAssets.length < state.filteredAssets.length;
        final icon = iconForCategory(widget.category.iconName);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(widget.category.name),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt_outlined),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth > 640 ? 32.0 : 20.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Summary',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          _cubit.setSearchQuery(value, retainCategory: true),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Cari aset di kategori ini',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (assets.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.45),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No assets for the selected filters',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    else
                      ...assets.map(
                        (asset) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AssetTile(
                            asset: asset,
                            icon: icon,
                            trailing: IconButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: _cubit,
                                      child: AddAssetScreen(asset: asset),
                                    ),
                                  ),
                                );
                                if (!context.mounted) return;
                                _cubit.selectCategory(widget.category.id);
                                _cubit.setSearchQuery(
                                  _searchController.text,
                                  retainCategory: true,
                                );
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (hasMore)
                      OutlinedButton(
                        onPressed: _cubit.loadMoreFilteredAssets,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Load More Assets'),
                      ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: navigationIndex,
          ),
        );
      },
    );
  }
}
