import "package:equatable/equatable.dart";

class AssetCategory extends Equatable {
  const AssetCategory({
    required this.id,
    required this.name,
    required this.iconName,
    this.departmentCode,
    this.description,
    this.totalAssets = 0,
    this.criticalCount = 0,
  });

  final String id;
  final String name;
  final String iconName;
  final String? departmentCode;
  final String? description;
  final int totalAssets;
  final int criticalCount;

  AssetCategory copyWith({
    String? id,
    String? name,
    String? iconName,
    String? departmentCode,
    String? description,
    int? totalAssets,
    int? criticalCount,
  }) {
    return AssetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      departmentCode: departmentCode ?? this.departmentCode,
      description: description ?? this.description,
      totalAssets: totalAssets ?? this.totalAssets,
      criticalCount: criticalCount ?? this.criticalCount,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'department_code': departmentCode,
    'description': description,
  };

  static AssetCategory fromMap(Map<String, dynamic> map) {
    final name = (map['name'] as String?) ?? 'Category';
    final icon = map['icon_name'] as String? ?? _guessIconName(name);
    final total = _toInt(map['total_assets'] ?? map['asset_count']);
    final critical = _toInt(map['critical_assets'] ?? map['critical_count']);

    return AssetCategory(
      id: (map['id'] ?? '').toString(),
      name: name,
      iconName: icon,
      departmentCode: (map['department_code'] as String?) ?? 'IT',
      description: map['description'] as String?,
      totalAssets: total,
      criticalCount: critical,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _guessIconName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('laptop') ||
        lower.contains('notebook') ||
        lower.contains('mac')) {
      return 'laptop_mac';
    }
    if (lower.contains('desktop') ||
        lower.contains('pc') ||
        lower.contains('workstation')) {
      return 'desktop_windows';
    }
    if (lower.contains('monitor') || lower.contains('display')) {
      return 'monitor';
    }
    if (lower.contains('cctv') || lower.contains('camera')) {
      return 'videocam';
    }
    if (lower.contains('ram') || lower.contains('memory')) {
      return 'memory';
    }
    if (lower.contains('processor') || lower.contains('cpu')) {
      return 'developer_board';
    }
    if (lower.contains('storage') ||
        lower.contains('drive') ||
        lower.contains('disk')) {
      return 'storage';
    }
    if (lower.contains('keyboard') || lower.contains('peripheral')) {
      return 'keyboard';
    }
    return 'devices_other';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconName,
    departmentCode,
    description,
    totalAssets,
    criticalCount,
  ];
}
