import 'package:hive/hive.dart';
import '../../domain/entities/asset_entity.dart';

@HiveType(typeId: 0)
class AssetModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String assetName;
  @HiveField(2) final String category;
  @HiveField(3) final double latitude;
  @HiveField(4) final double longitude;
  @HiveField(5) final DateTime timestamp;
  @HiveField(6) final String status;
  @HiveField(7) final String syncStatusStr;

  AssetModel({
    required this.id,
    required this.assetName,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    required this.syncStatusStr,
  });

  factory AssetModel.fromEntity(AssetEntity entity) {
    return AssetModel(
      id: entity.id,
      assetName: entity.assetName,
      category: entity.category,
      latitude: entity.latitude,
      longitude: entity.longitude,
      timestamp: entity.timestamp,
      status: entity.status,
      syncStatusStr: entity.syncStatus == SyncStatus.synced ? 'synced' : 'pendingSync',
    );
  }

  AssetEntity toEntity() {
    return AssetEntity(
      id: id,
      assetName: assetName,
      category: category,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      status: status,
      syncStatus: syncStatusStr == 'synced' ? SyncStatus.synced : SyncStatus.pendingSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetName': assetName,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      assetName: json['assetName'] as String,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      syncStatusStr: 'synced',
    );
  }

  AssetModel copyWith({String? syncStatusStr}) {
    return AssetModel(
      id: id,
      assetName: assetName,
      category: category,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      status: status,
      syncStatusStr: syncStatusStr ?? this.syncStatusStr,
    );
  }
}

// MANUALLY CODED HIVE ADAPTER (Bypasses Git/Build Runner Errors)
class AssetModelAdapter extends TypeAdapter<AssetModel> {
  @override final int typeId = 0;

  @override
  AssetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return AssetModel(
      id: fields[0] as String,
      assetName: fields[1] as String,
      category: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      timestamp: fields[5] as DateTime,
      status: fields[6] as String,
      syncStatusStr: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AssetModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.assetName)
      ..writeByte(2)..write(obj.category)
      ..writeByte(3)..write(obj.latitude)
      ..writeByte(4)..write(obj.longitude)
      ..writeByte(5)..write(obj.timestamp)
      ..writeByte(6)..write(obj.status)
      ..writeByte(7)..write(obj.syncStatusStr);
  }
}