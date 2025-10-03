import 'package:equatable/equatable.dart';

class MaintenanceEntry extends Equatable {
  const MaintenanceEntry({
    required this.id,
    required this.assetId,
    required this.description,
    required this.date,
  });

  final String id;
  final String assetId;
  final String description;
  final DateTime date;

  Map<String, dynamic> toMap() => {
    'id': id,
    'asset_id': assetId,
    'description': description,
    'date': date.toIso8601String(),
  };

  static MaintenanceEntry fromMap(Map<String, dynamic> map) => MaintenanceEntry(
    id: map['id'] as String,
    assetId: map['asset_id'] as String,
    description: map['description'] as String,
    date: DateTime.parse(map['date'] as String),
  );

  @override
  List<Object> get props => [id, assetId, description, date];
}
