import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/icon_mapper.dart';
import '../../../domain/models/asset_status.dart';
import '../../bloc/asset/asset_cubit.dart';
import '../../bloc/asset/asset_state.dart';
import '../../bloc/navigation/navigation_cubit.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/asset_tile.dart';
import '../add_asset/add_asset_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AssetCubit>();
    _controller = TextEditingController(text: cubit.state.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.clearCategorySelection(resetStatus: true);
      if (_controller.text != cubit.state.searchQuery) {
        _controller.text = cubit.state.searchQuery;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationIndex = context.watch<NavigationCubit>().state;

    return BlocBuilder<AssetCubit, AssetState>(
      builder: (context, state) {
        if (state.isLoading && state.assets.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cubit = context.read<AssetCubit>();
        final categories = {for (final c in state.categories) c.id: c};
        final assets = state.visibleFilteredAssets;
        final hasMore =
            state.visibleFilteredAssets.length < state.filteredAssets.length;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Search Assets'),
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
                    TextField(
                      controller: _controller,
                      onChanged: cubit.setSearchQuery,
                      onSubmitted: cubit.setSearchQuery,
                      textInputAction: TextInputAction.search,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search assets by name, serial, or branch',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusChip(
                            label: 'All Assets',
                            selected: state.statusFilter == AssetStatus.all,
                            onTap: () => cubit.setStatusFilter(AssetStatus.all),
                          ),
                          ...AssetStatus.values
                              .where((status) => status != AssetStatus.all)
                              .map(
                                (status) => _StatusChip(
                                  label: status.label,
                                  selected: state.statusFilter == status,
                                  onTap: () => cubit.setStatusFilter(status),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Showing ${assets.length} of ${state.filteredAssets.length} results',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                              Icons.search_off,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.45),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No assets found',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try adjusting your filters or search query.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...assets.map((asset) {
                        final category = categories[asset.categoryId];
                        final icon = iconForCategory(category?.iconName);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AssetTile(
                            asset: asset,
                            icon: icon,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.9),
                                  ),
                                  tooltip: 'Edit asset',
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<AssetCubit>(),
                                          child: AddAssetScreen(asset: asset),
                                        ),
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    cubit.setSearchQuery(_controller.text);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFE11D48),
                                  ),
                                  tooltip: 'Delete asset',
                                  onPressed: () async {
                                    final confirmed =
                                        await showDeleteConfirmationDialog(
                                      context: context,
                                      title: 'Hapus Aset',
                                      message:
                                          'Yakin ingin menghapus aset "${asset.name}"? Tindakan ini tidak bisa dibatalkan.',
                                    );
                                    if (!confirmed || !context.mounted) {
                                      return;
                                    }
                                    await context
                                        .read<AssetCubit>()
                                        .deleteAsset(asset.id);
                                    if (!context.mounted) return;
                                    cubit.setSearchQuery(_controller.text);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                    if (hasMore)
                      OutlinedButton(
                        onPressed: cubit.loadMoreFilteredAssets,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = selected ? const Color(0xFFE5E7EB) : Colors.white;
    final borderColor = selected ? Colors.black : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        label: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: backgroundColor,
        backgroundColor: Colors.white,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        pressElevation: 0,
      ),
    );
  }
}
