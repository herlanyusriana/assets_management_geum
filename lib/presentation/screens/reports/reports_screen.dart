import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/asset_status.dart';
import '../../bloc/asset/asset_cubit.dart';
import '../../bloc/asset/asset_state.dart';
import '../../bloc/navigation/navigation_cubit.dart';
import '../../widgets/app_bottom_navigation.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationIndex = context.watch<NavigationCubit>().state;
    return BlocBuilder<AssetCubit, AssetState>(
      builder: (context, state) {
        final statusCounts = _buildStatusCounts(state);
        final total = state.totalAssets == 0 ? 1 : state.totalAssets;
        final topCategories = [...state.categories]
          ..sort((a, b) => b.criticalCount.compareTo(a.criticalCount));
        final recentAdditions = _countRecentAdditions(state);
        final maintenanceDue = state.assets
            .where(
              (asset) =>
                  asset.status == AssetStatus.maintenance ||
                  asset.status == AssetStatus.needsCheck,
            )
            .length;

        return Scaffold(
          appBar: AppBar(title: const Text('Reports')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth > 720 ? 32.0 : 20.0;
              final isWide = constraints.maxWidth > 900;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Assets',
                              value: state.totalAssets.toString(),
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Critical Assets',
                              value: state.criticalAssets.toString(),
                              icon: Icons.warning_amber_outlined,
                              accentColor: const Color(0xFFFFEDD5),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Recent Additions (7d)',
                              value: recentAdditions.toString(),
                              icon: Icons.new_releases_outlined,
                              accentColor: const Color(0xFFE0F2FE),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Needs Attention',
                              value: maintenanceDue.toString(),
                              icon: Icons.build_circle_outlined,
                              accentColor: const Color(0xFFFEE2E2),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _SummaryCard(
                            title: 'Total Assets',
                            value: state.totalAssets.toString(),
                            icon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(height: 12),
                          _SummaryCard(
                            title: 'Critical Assets',
                            value: state.criticalAssets.toString(),
                            icon: Icons.warning_amber_outlined,
                            accentColor: const Color(0xFFFFEDD5),
                          ),
                          const SizedBox(height: 12),
                          _SummaryCard(
                            title: 'Recent Additions (7d)',
                            value: recentAdditions.toString(),
                            icon: Icons.new_releases_outlined,
                            accentColor: const Color(0xFFE0F2FE),
                          ),
                          const SizedBox(height: 12),
                          _SummaryCard(
                            title: 'Needs Attention',
                            value: maintenanceDue.toString(),
                            icon: Icons.build_circle_outlined,
                            accentColor: const Color(0xFFFEE2E2),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                    Text(
                      'Status Distribution',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: statusCounts.entries.map((entry) {
                        final percentage = entry.value / total;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StatusDistributionTile(
                            status: entry.key,
                            count: entry.value,
                            percentage: percentage,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Categories with Most Critical Assets',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...topCategories
                        .take(5)
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryHealthTile(
                              name: category.name,
                              total: category.totalAssets,
                              critical: category.criticalCount,
                            ),
                          ),
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

  Map<AssetStatus, int> _buildStatusCounts(AssetState state) {
    final counts = <AssetStatus, int>{
      for (final status in AssetStatus.values) status: 0,
    };

    for (final asset in state.assets) {
      counts[asset.status] = (counts[asset.status] ?? 0) + 1;
    }

    counts.remove(AssetStatus.all);
    return counts;
  }

  int _countRecentAdditions(AssetState state) {
    final now = DateTime.now();
    final threshold = now.subtract(const Duration(days: 7));
    return state.assets.where((asset) {
      final created = asset.createdAt;
      return created != null && created.isAfter(threshold);
    }).length;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF1F2937)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDistributionTile extends StatelessWidget {
  const _StatusDistributionTile({
    required this.status,
    required this.count,
    required this.percentage,
  });

  final AssetStatus status;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status.label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$count aset',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percentage.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(status.chipTextColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHealthTile extends StatelessWidget {
  const _CategoryHealthTile({
    required this.name,
    required this.total,
    required this.critical,
  });

  final String name;
  final int total;
  final int critical;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : critical / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '$critical critical out of $total assets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: ratio.clamp(0, 1),
                    backgroundColor: const Color(0xFFF1F5F9),
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio > 0.6
                          ? const Color(0xFFB91C1C)
                          : ratio > 0.3
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                    ),
                  ),
                ),
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
