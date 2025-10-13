import 'dart:typed_data';

class AssetReportFile {
  const AssetReportFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}
