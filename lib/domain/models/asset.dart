import 'package:equatable/equatable.dart';

import 'asset_status.dart';
import 'maintenance_entry.dart';

class Asset extends Equatable {
  const Asset({
    required this.id,
    required this.name,
    required this.barcode,
    required this.serialNumber,
    required this.categoryId,
    required this.status,
    required this.department,
    this.assignedTo,
    this.assignedAvatar,
    this.location,
    this.brand,
    this.model,
    this.processorName,
    this.ramCapacity,
    this.storageType,
    this.storageBrand,
    this.storageCapacity,
    this.purchaseDate,
    this.purchasePrice,
    this.warrantyExpiry,
    this.notes,
    this.assetPhotoPath,
    this.assetPhotoUrl,
    this.createdAt,
    this.custodianId,
    this.maintenanceHistory = const [],
  });

  final String id;
  final String name;
  final String barcode;
  final String serialNumber;
  final String categoryId;
  final AssetStatus status;
  final String department;
  final String? assignedTo;
  final String? assignedAvatar;
  final String? location;
  final String? brand;
  final String? model;
  final String? processorName;
  final String? ramCapacity;
  final String? storageType;
  final String? storageBrand;
  final String? storageCapacity;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final DateTime? warrantyExpiry;
  final String? notes;
  final String? assetPhotoPath;
  final String? assetPhotoUrl;
  final DateTime? createdAt;
  final String? custodianId;
  final List<MaintenanceEntry> maintenanceHistory;

  Asset copyWith({
    String? id,
    String? name,
    String? barcode,
    String? serialNumber,
    String? categoryId,
    AssetStatus? status,
    String? department,
    String? assignedTo,
    String? assignedAvatar,
    String? location,
    String? brand,
    String? model,
    String? processorName,
    String? ramCapacity,
    String? storageType,
    String? storageBrand,
    String? storageCapacity,
    DateTime? purchaseDate,
    double? purchasePrice,
    DateTime? warrantyExpiry,
    String? notes,
    String? assetPhotoPath,
    String? assetPhotoUrl,
    DateTime? createdAt,
    String? custodianId,
    List<MaintenanceEntry>? maintenanceHistory,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      serialNumber: serialNumber ?? this.serialNumber,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      department: department ?? this.department,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedAvatar: assignedAvatar ?? this.assignedAvatar,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      processorName: processorName ?? this.processorName,
      ramCapacity: ramCapacity ?? this.ramCapacity,
      storageType: storageType ?? this.storageType,
      storageBrand: storageBrand ?? this.storageBrand,
      storageCapacity: storageCapacity ?? this.storageCapacity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      notes: notes ?? this.notes,
      assetPhotoPath: assetPhotoPath ?? this.assetPhotoPath,
      assetPhotoUrl: assetPhotoUrl ?? this.assetPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      custodianId: custodianId ?? this.custodianId,
      maintenanceHistory: maintenanceHistory ?? this.maintenanceHistory,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'asset_code': barcode,
    'barcode': barcode,
    'serial_number': serialNumber,
    'asset_category_id': categoryId,
    'status': status.apiValue,
    'department': department,
    'assigned_to': assignedTo,
    'custodian_name': assignedTo,
    'assigned_avatar': assignedAvatar,
    'location': location,
    'brand': brand,
    'model': model,
    'processor_name': processorName,
    'ram_capacity': ramCapacity,
    'storage_type': storageType,
    'storage_brand': storageBrand,
    'storage_capacity': storageCapacity,
    'purchase_date': purchaseDate?.toIso8601String(),
    'purchase_price': purchasePrice,
    'warranty_expiry': warrantyExpiry?.toIso8601String(),
    'condition_notes': notes,
    'asset_photo_path': assetPhotoPath,
    'asset_photo_url': assetPhotoUrl,
    'created_at': createdAt?.toIso8601String(),
    'current_custodian_id': custodianId,
  };

  static Asset fromMap(
    Map<String, dynamic> map, {
    List<MaintenanceEntry> maintenanceHistory = const [],
  }) {
    final normalized = Map<String, dynamic>.from(map);
    final category = (normalized['category'] as Map?)?.cast<String, dynamic>();
    final custodian = (normalized['custodian'] as Map?)
        ?.cast<String, dynamic>();
    final rawCustodianName =
        custodian?['name'] as String? ??
        (normalized['custodian_name'] as String?);
    final custodianName = rawCustodianName != null
        ? (rawCustodianName.trim().isEmpty ? null : rawCustodianName.trim())
        : null;
    final idValue =
        normalized['id'] ??
        normalized['asset_code'] ??
        normalized['serial_number'] ??
        '';
    final rawBarcode =
        normalized['barcode'] ?? normalized['asset_code'] ?? normalized['code'];
    final barcode = rawBarcode == null ? '' : rawBarcode.toString();
    final rawSerial = normalized['serial_number'];
    final serial = rawSerial == null ? '' : rawSerial.toString();
    final effectiveSerial = serial.isNotEmpty
        ? serial
        : (barcode.isNotEmpty ? barcode : idValue.toString());
    final effectiveBarcode = barcode.isNotEmpty ? barcode : effectiveSerial;
    final categoryIdValue =
        category?['id'] ?? normalized['asset_category_id'] ?? '';
    final department =
        category?['department_code'] ?? normalized['department'] ?? 'Unknown';

    return Asset(
      id: idValue.toString(),
      name: (normalized['name'] as String?) ?? '',
      barcode: effectiveBarcode,
      serialNumber: effectiveSerial,
      categoryId: categoryIdValue.toString(),
      status: AssetStatusApi.fromApi(
        (normalized['status'] as String?)?.toLowerCase(),
      ),
      department: department.toString(),
      assignedTo: custodianName,
      assignedAvatar: custodian?['avatar'] as String?,
      location: normalized['location'] as String?,
      brand: normalized['brand'] as String?,
      model: normalized['model'] as String?,
      processorName: normalized['processor_name'] as String?,
      ramCapacity: normalized['ram_capacity'] as String?,
      storageType: normalized['storage_type'] as String?,
      storageBrand: normalized['storage_brand'] as String?,
      storageCapacity: normalized['storage_capacity'] as String?,
      purchaseDate: _parseDate(normalized['purchase_date']),
      purchasePrice: _parseDouble(normalized['purchase_price']),
      warrantyExpiry: _parseDate(normalized['warranty_expiry']),
      notes:
          (normalized['condition_notes'] as String?) ??
          normalized['notes'] as String?,
      assetPhotoPath: normalized['asset_photo_path'] as String?,
      assetPhotoUrl: normalized['asset_photo_url'] as String?,
      createdAt: _parseDateTime(normalized['created_at']),
      custodianId: custodian?['id']?.toString(),
      maintenanceHistory: maintenanceHistory,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) => _parseDate(value);

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    barcode,
    serialNumber,
    categoryId,
    status,
    department,
    assignedTo,
    assignedAvatar,
    location,
    brand,
    model,
    processorName,
    ramCapacity,
    storageType,
    storageBrand,
    storageCapacity,
    purchaseDate,
    purchasePrice,
    warrantyExpiry,
    notes,
    assetPhotoPath,
    assetPhotoUrl,
    createdAt,
    custodianId,
    maintenanceHistory,
  ];
}
