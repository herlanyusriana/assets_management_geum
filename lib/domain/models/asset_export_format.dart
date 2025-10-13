enum AssetExportFormat {
  excel,
  pdf;

  String get queryValue {
    switch (this) {
      case AssetExportFormat.pdf:
        return 'pdf';
      case AssetExportFormat.excel:
        return 'excel';
    }
  }

  String get recommendedExtension {
    return this == AssetExportFormat.pdf ? 'pdf' : 'csv';
  }
}
