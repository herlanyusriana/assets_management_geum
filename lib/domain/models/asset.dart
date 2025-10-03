import 'package:equatable/equatable.dart';

import 'asset_status.dart';
import 'maintenance_entry.dart';

class Asset extends Equatable {
  const Asset({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.categoryId,
    required this.status,
    required this.department,
    this.assignedTo,
    this.assignedAvatar,
    this.location,
    this.brand,
    this.model,
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
  final String serialNumber;
  final String categoryId;
  final AssetStatus status;
  final String department;
  final String? assignedTo;
  final String? assignedAvatar;
  final String? location;
  final String? brand;
  final String? model;
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
    String? serialNumber,
    String? categoryId,
    AssetStatus? status,
    String? department,
    String? assignedTo,
    String? assignedAvatar,
    String? location,
    String? brand,
    String? model,
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
      serialNumber: serialNumber ?? this.serialNumber,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      department: department ?? this.department,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedAvatar: assignedAvatar ?? this.assignedAvatar,
      location: location ?? this.location,
      brand: brand ?? this.brand,
      model: model ?? this.model,
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
    'asset_code': serialNumber,
    'serial_number': serialNumber,
    'asset_category_id': categoryId,
    'status': status.apiValue,
    'department': department,
    'assigned_to': assignedTo,
    'assigned_avatar': assignedAvatar,
    'location': location,
    'brand': brand,
    'model': model,
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
    final custodian =
        (normalized['custodian'] as Map?)?.cast<String, dynamic>();
    final idValue =
        normalized['id'] ??
        normalized['asset_code'] ??
        normalized['serial_number'] ??
        '';
    final serial =
        (normalized['serial_number'] ?? normalized['asset_code'] ?? '')
            .toString();
    final categoryIdValue =
        category?['id'] ?? normalized['asset_category_id'] ?? '';
    final department =
        category?['department_code'] ?? normalized['department'] ?? 'Unknown';

    return Asset(
      id: idValue.toString(),
      name: (normalized['name'] as String?) ?? '',
      serialNumber: serial.isEmpty ? idValue.toString() : serial,
      categoryId: categoryIdValue.toString(),
      status: AssetStatusApi.fromApi(
        (normalized['status'] as String?)?.toLowerCase(),
      ),
      department: department.toString(),
      assignedTo: custodian?['name'] as String?,
      assignedAvatar: custodian?['avatar'] as String?,
      location: normalized['location'] as String?,
      brand: normalized['brand'] as String?,
      model: normalized['model'] as String?,
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
    serialNumber,
    categoryId,
    status,
    department,
    assignedTo,
    assignedAvatar,
    location,
    brand,
    model,
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
