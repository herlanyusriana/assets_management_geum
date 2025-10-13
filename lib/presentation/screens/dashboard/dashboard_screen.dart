import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import '../../../core/theme/app_colors.dart';
import '../../bloc/asset/asset_cubit.dart';
import '../../bloc/asset/asset_state.dart';
import '../../bloc/navigation/navigation_cubit.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/asset_category_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/stat_card.dart';
import '../add_asset/add_asset_screen.dart';
import '../category/category_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetCubit, AssetState>(
      builder: (context, state) {
        final navigationIndex = context.watch<NavigationCubit>().state;
        if (state.isLoading && state.categories.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = state.categories
            .where(
              (category) =>
                  (category.departmentCode ?? 'IT').toUpperCase() == 'IT',
            )
            .toList();

        return Scaffold(
          appBar: const _DashboardAppBar(),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 640
                  ? 32.0
                  : 20.0;
              final isWide = constraints.maxWidth > 800;

              return RefreshIndicator(
                onRefresh: () => context.read<AssetCubit>().refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.successMessage != null ||
                          state.errorMessage != null) ...[
                        _InfoBanner(
                          message: state.successMessage ?? state.errorMessage!,
                          isError: state.errorMessage != null,
                          onClose: () =>
                              context.read<AssetCubit>().dismissMessage(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _SummarySection(
                        totalAssets: state.totalAssets,
                        criticalAssets: state.criticalAssets,
                        isWide: isWide,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Asset Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (categories.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF9CA3AF),
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada kategori untuk departemen Anda.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      else
                        ...categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AssetCategoryCard(
                              category: category,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<AssetCubit>(),
                                      child: CategoryScreen(category: category),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Add Asset',
                        icon: Icons.add,
                        backgroundColor: Colors.black,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<AssetCubit>(),
                                child: const AddAssetScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
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

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset Management',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Welcome back',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.notifications_none, color: Color(0xFF4B5563)),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          backgroundColor: const Color(0xFFE5E7EB),
          child: Text('JS', style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.totalAssets,
    required this.criticalAssets,
    required this.isWide,
  });

  final int totalAssets;
  final int criticalAssets;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Total Assets',
              value: totalAssets.toString(),
              icon: Icons.computer_outlined,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              title: 'Critical',
              value: criticalAssets.toString(),
              icon: Icons.error_outline,
              backgroundColor: _criticalBackground(context),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        StatCard(
          title: 'Total Assets',
          value: totalAssets.toString(),
          icon: Icons.computer_outlined,
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Critical',
          value: criticalAssets.toString(),
          icon: Icons.error_outline,
          backgroundColor: _criticalBackground(context),
        ),
      ],
    );
  }

  Color _criticalBackground(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return Color.alphaBlend(
        const Color(0xFFFF4D67).withValues(alpha: 0.18),
        theme.colorScheme.surface,
      );
    }
    return const Color(0xFFFFF5F5);
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.isError,
    required this.onClose,
  });

  final String message;
  final bool isError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isError ? Colors.red.shade50 : Colors.green.shade50;
    final borderColor = isError ? Colors.red.shade200 : Colors.green.shade200;
    final iconColor = isError ? Colors.red.shade600 : Colors.green;
    final textColor = isError ? Colors.red.shade800 : Colors.green.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
            color: textColor,
          ),
        ],
      ),
    );
  }
}
