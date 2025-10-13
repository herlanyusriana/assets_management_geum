import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/utils/icon_mapper.dart';
import '../../../domain/models/asset_category.dart';
import '../../bloc/asset/asset_cubit.dart';
import '../../bloc/navigation/navigation_cubit.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/asset_tile.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 500,
  );
  bool _isProcessing = false;
  String? _lastScanned;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationIndex = context.watch<NavigationCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Asset')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) => _onDetect(context, capture),
          ),
          const _ScannerOverlay(),
          Positioned(
            bottom: 32,
            left: 32,
            right: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Arahkan kamera ke QR aset',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastScanned == null
                            ? 'QR yang terbaca akan otomatis membuka detail'
                            : 'Terakhir: $_lastScanned',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  onPressed: () => _controller.toggleTorch(),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Torch'),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(currentIndex: navigationIndex),
    );
  }

  Future<void> _onDetect(BuildContext context, BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstWhere(
      (code) => (code.rawValue ?? '').isNotEmpty,
      orElse: () => Barcode(rawValue: null),
    );
    final value = barcode.rawValue;
    if (value == null || value == _lastScanned) return;

    setState(() {
      _isProcessing = true;
      _lastScanned = value;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final modalContext = context;
    final cubit = context.read<AssetCubit>();
    final asset = await cubit.findAssetByCode(value);

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (asset == null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Asset dengan QR "$value" tidak ditemukan.')),
      );
      return;
    }

    final categories = cubit.state.categories;
    IconData icon = Icons.qr_code_2;
    AssetCategory? categoryMatch;
    for (final category in categories) {
      if (category.id == asset.categoryId) {
        categoryMatch = category;
        break;
      }
    }
    if (categoryMatch != null) {
      icon = iconForCategory(categoryMatch.iconName);
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: modalContext, // ignore: use_build_context_synchronously
      isScrollControlled: true,
      builder: (_) => AssetDetailSheet(asset: asset, icon: icon),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.85);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final base = math.min(size.width, size.height);
          final overlaySize = math.max(160.0, math.min(base * 0.65, 260.0));
          final borderRadius = BorderRadius.circular(28);

          return Stack(
            children: [
              Center(
                child: Container(
                  width: overlaySize,
                  height: overlaySize,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(color: color, width: 2),
                    color: Colors.transparent,
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: overlaySize,
                  height: overlaySize,
                  child: CustomPaint(painter: _CornerPainter(color)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = math.min(size.width, size.height) * 0.22;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), paint);
    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );
    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );
    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
