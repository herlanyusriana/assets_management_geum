import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/asset_export_format.dart';
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isWide ? 220 : double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _exportReport(context, AssetExportFormat.excel),
                            icon: const Icon(Icons.table_view_outlined),
                            label: const Text('Export Excel'),
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 220 : double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _exportReport(context, AssetExportFormat.pdf),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Export PDF'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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

  Future<void> _exportReport(
    BuildContext context,
    AssetExportFormat format,
  ) async {
    final cubit = context.read<AssetCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final report = await cubit.exportAssets(format);
      navigator.pop();

      final directory = await _resolveDownloadDirectory();
      final filename = report.filename.isNotEmpty
          ? report.filename
          : 'assets-report.${format.recommendedExtension}';
      final path = p.join(directory.path, filename);
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsBytes(report.bytes, flush: true);

      messenger.showSnackBar(
        SnackBar(content: Text('Laporan tersimpan di $path')),
      );
      final openResult = await OpenFilex.open(path);
      final message = openResult.type == ResultType.done
          ? 'Laporan tersimpan di '
          : 'Laporan tersimpan di  (tidak dapat dibuka otomatis)';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      navigator.maybePop();
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengekspor laporan: $error')),
      );
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        await downloads.create(recursive: true);
        return downloads;
      }
    } catch (_) {}

    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        final dir = Directory(p.join(external.path, 'Download'));
        await dir.create(recursive: true);
        return dir;
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    await documents.create(recursive: true);
    return documents;
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = accentColor ?? colors.surface;
    final borderColor = colors.onSurface.withValues(alpha: 0.06);
    final capsuleColor = accentColor != null
        ? accentColor!.withValues(alpha: 0.45)
        : colors.primary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: capsuleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: colors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count aset',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percentage.clamp(0, 1),
              minHeight: 10,
              backgroundColor: colors.primary.withValues(alpha: 0.08),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ratio = total == 0 ? 0.0 : critical / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$critical critical out of $total assets',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
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
                    backgroundColor: colors.primary.withValues(alpha: 0.08),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
