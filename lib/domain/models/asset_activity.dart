import 'package:equatable/equatable.dart';

class AssetActivity extends Equatable {
  const AssetActivity({
    required this.id,
    required this.assetId,
    required this.title,
    required this.description,
    required this.timestamp,
    this.type,
  });

  final String id;
  final String assetId;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? type;

  Map<String, dynamic> toMap() => {
    'id': id,
    'asset_id': assetId,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
  };

  static AssetActivity fromMap(Map<String, dynamic> map) => AssetActivity(
    id: map['id'] as String,
    assetId: map['asset_id'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
    type: map['type'] as String?,
  );

  @override
  List<Object?> get props => [id, assetId, title, description, timestamp, type];
}
