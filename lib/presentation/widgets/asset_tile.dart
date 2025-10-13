import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/asset_status.dart';
import 'status_chip.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({
    super.key,
    required this.asset,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  final Asset asset;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  bool get _hasSpecs =>
      (asset.processorName?.trim().isNotEmpty ?? false) ||
      (asset.ramCapacity?.trim().isNotEmpty ?? false) ||
      (asset.storageCapacity?.trim().isNotEmpty ?? false) ||
      (asset.storageType?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap ?? () => _showAssetDetail(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeading(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          asset.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Barcode: ${asset.barcode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  if (asset.serialNumber.isNotEmpty &&
                      asset.serialNumber != asset.barcode)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'SN: ${asset.serialNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  if (_hasSpecs) ...[
                    const SizedBox(height: 6),
                    Text(
                      _buildSpecPreview(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (asset.brand?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        asset.brand,
                        if (asset.model != null &&
                            asset.model!.trim().isNotEmpty)
                          asset.model,
                      ].whereType<String>().join(' | '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StatusChip(status: asset.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          asset.assignedTo ?? asset.department,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (asset.maintenanceHistory.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: asset.maintenanceHistory.take(2).map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '- ${entry.description}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (asset.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ditambahkan ${DateUtilsX.formatRelative(asset.createdAt!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 28, color: colors.primary),
    );
  }

  String _buildSpecPreview() {
    final storageParts = <String>[
      if (asset.storageCapacity?.trim().isNotEmpty ?? false)
        asset.storageCapacity!.trim(),
      if (asset.storageType?.trim().isNotEmpty ?? false)
        asset.storageType!.trim(),
    ];

    final parts = <String>[
      if (asset.processorName?.trim().isNotEmpty ?? false)
        asset.processorName!.trim(),
      if (asset.ramCapacity?.trim().isNotEmpty ?? false)
        asset.ramCapacity!.trim(),
      if (storageParts.isNotEmpty) storageParts.join(' '),
    ];

    return parts.join(' | ');
  }

  void _showAssetDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: AssetDetailSheet(asset: asset, icon: icon),
        );
      },
    );
  }
}

class AssetDetailSheet extends StatelessWidget {
  const AssetDetailSheet({super.key, required this.asset, required this.icon});

  final Asset asset;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final specItems = _buildSpecItems();
    final purchaseDate = _formatDate(asset.purchaseDate);
    final warrantyDate = _formatDate(asset.warrantyExpiry);
    final price = _formatPrice(asset.purchasePrice);
    final canPrint = _barcodeValue.isNotEmpty;
    final assignedName =
        asset.assignedTo != null && asset.assignedTo!.trim().isNotEmpty
        ? asset.assignedTo!.trim()
        : null;
    final quickFacts = <_QuickFact>[
      _QuickFact(
        icon: Icons.apartment_outlined,
        label: 'Departemen',
        value: asset.department,
      ),
      if (asset.location?.trim().isNotEmpty ?? false)
        _QuickFact(
          icon: Icons.place_outlined,
          label: 'Lokasi',
          value: asset.location!.trim(),
        ),
      if (assignedName != null)
        _QuickFact(
          icon: Icons.badge_outlined,
          label: 'Penanggung Jawab',
          value: assignedName,
        ),
      if (asset.createdAt != null)
        _QuickFact(
          icon: Icons.event_note_outlined,
          label: 'Didaftarkan',
          value: DateFormat('d MMM yyyy', 'id_ID').format(asset.createdAt!),
        ),
    ];
    final generalInfoTiles = <Widget>[
      if ((asset.brand?.trim().isNotEmpty ?? false) ||
          (asset.model?.trim().isNotEmpty ?? false))
        _InfoTile(
          icon: Icons.devices_other_outlined,
          label: 'Perangkat',
          value: [
            if (asset.brand?.trim().isNotEmpty ?? false) asset.brand!.trim(),
            if (asset.model?.trim().isNotEmpty ?? false) asset.model!.trim(),
          ].join(' · '),
        ),
      if (asset.serialNumber.isNotEmpty && asset.serialNumber != asset.barcode)
        _InfoTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Serial Number',
          value: asset.serialNumber,
        ),
      if (assignedName == null)
        const _InfoTile(
          icon: Icons.badge_outlined,
          label: 'Penanggung Jawab',
          value: 'Belum ditentukan',
        ),
      if (!(asset.location?.trim().isNotEmpty ?? false))
        const _InfoTile(
          icon: Icons.place_outlined,
          label: 'Lokasi',
          value: 'Belum diatur',
        ),
    ];
    final purchaseTiles = <Widget>[
      if (purchaseDate != null)
        _InfoTile(
          icon: Icons.event_available_outlined,
          label: 'Tanggal Pembelian',
          value: purchaseDate,
        ),
      if (warrantyDate != null)
        _InfoTile(
          icon: Icons.verified_user_outlined,
          label: 'Garansi Hingga',
          value: warrantyDate,
        ),
      if (price != null)
        _InfoTile(
          icon: Icons.price_change_outlined,
          label: 'Harga Pembelian',
          value: price,
        ),
    ];
    final maintenanceTiles = <Widget>[];
    for (var i = 0; i < asset.maintenanceHistory.length; i++) {
      final entry = asset.maintenanceHistory[i];
      final entryDate = DateFormat('d MMM yyyy', 'id_ID').format(entry.date);
      maintenanceTiles.add(
        _MaintenanceTile(date: entryDate, description: entry.description),
      );
      if (i != asset.maintenanceHistory.length - 1) {
        maintenanceTiles.add(const Divider(height: 16));
      }
    }
    final notes = asset.notes?.trim();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    if (canPrint)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () => _printBarcode(context),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Cetak QR Code'),
                        ),
                      ),
                    if (canPrint) const SizedBox(height: 20),
                    if (quickFacts.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            colors.primary.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.12
                                  : 0.05,
                            ),
                            colors.surfaceContainerHighest.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: quickFacts
                              .map((fact) => _QuickFactCard(fact: fact))
                              .toList(),
                        ),
                      ),
                    if (generalInfoTiles.isNotEmpty)
                      _SectionCard(
                        title: 'Informasi Umum',
                        children: generalInfoTiles,
                      ),
                    if (specItems.isNotEmpty)
                      _SectionCard(
                        title: 'Spesifikasi',
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: specItems
                                .map(
                                  (spec) => Chip(
                                    label: Text(spec),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    if (purchaseTiles.isNotEmpty)
                      _SectionCard(
                        title: 'Riwayat Pembelian',
                        children: purchaseTiles,
                      ),
                    if (notes != null && notes.isNotEmpty)
                      _SectionCard(
                        title: 'Catatan Kondisi',
                        children: [
                          Text(
                            notes,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    if (maintenanceTiles.isNotEmpty)
                      _SectionCard(
                        title: 'Riwayat Perawatan',
                        children: maintenanceTiles,
                      ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printBarcode(BuildContext context) async {
    final value = _barcodeValue;
    if (value.isEmpty) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      pw.ImageProvider? logoImage;
      try {
        final data = await rootBundle.load('assets/logo-big.jpg');
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }

      final labelSize = 62 * PdfPageFormat.mm;
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(labelSize, labelSize),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context _) {
            return pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null) ...[
                      pw.SizedBox(
                        width: 92,
                        height: 38,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 14),
                    ],
                    pw.Container(
                      width: 110,
                      height: 110,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 0.6,
                        ),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: value,
                        drawText: false,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      value,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (error) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Gagal mencetak QR: $error')),
      );
    }
  }

  String get _barcodeValue => asset.barcode.isNotEmpty
      ? asset.barcode
      : (asset.serialNumber.isNotEmpty ? asset.serialNumber : asset.id);

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final assignedName =
        asset.assignedTo != null && asset.assignedTo!.trim().isNotEmpty
        ? asset.assignedTo!.trim()
        : null;
    final statusSupplement =
        asset.status == AssetStatus.assigned && assignedName != null
        ? 'Ditugaskan ke $assignedName'
        : null;
    final createdLabel = asset.createdAt != null
        ? DateFormat('d MMM yyyy', 'id_ID').format(asset.createdAt!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailHeaderBadge(theme),
        const SizedBox(height: 16),
        Text(
          asset.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StatusChip(status: asset.status),
            if (statusSupplement != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusSupplement,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (createdLabel != null) ...[
          const SizedBox(height: 12),
          Text(
            'Terdaftar sejak $createdLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailHeaderBadge(ThemeData theme) {
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: colors.primary),
          const SizedBox(height: 14),
          Text(
            asset.barcode,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (asset.serialNumber.isNotEmpty &&
              asset.serialNumber != asset.barcode) ...[
            const SizedBox(height: 6),
            Text(
              'SN: ${asset.serialNumber}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _buildSpecItems() {
    final specs = <String>[];
    if (asset.processorName?.trim().isNotEmpty ?? false) {
      specs.add(asset.processorName!.trim());
    }
    if (asset.ramCapacity?.trim().isNotEmpty ?? false) {
      specs.add('RAM ${asset.ramCapacity!.trim()}');
    }
    final storageParts = <String>[];
    if (asset.storageCapacity?.trim().isNotEmpty ?? false) {
      storageParts.add(asset.storageCapacity!.trim());
    }
    if (asset.storageType?.trim().isNotEmpty ?? false) {
      storageParts.add(asset.storageType!.trim());
    }
    if (asset.storageBrand?.trim().isNotEmpty ?? false) {
      storageParts.add(asset.storageBrand!.trim());
    }
    if (storageParts.isNotEmpty) {
      specs.add('Storage ${storageParts.join(' ')}');
    }
    return specs;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  String? _formatPrice(double? value) {
    if (value == null) return null;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}

class _QuickFact {
  const _QuickFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _QuickFactCard extends StatelessWidget {
  const _QuickFactCard({required this.fact});

  final _QuickFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = Color.alphaBlend(
      colors.primary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08,
      ),
      colors.surface,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(fact.icon, size: 18, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              fact.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fact.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = Color.alphaBlend(
      colors.surfaceContainerHighest.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12,
      ),
      colors.surface,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
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

class _MaintenanceTile extends StatelessWidget {
  const _MaintenanceTile({
    required this.date,
    required this.description,
  });

  final String date;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.build_outlined, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
