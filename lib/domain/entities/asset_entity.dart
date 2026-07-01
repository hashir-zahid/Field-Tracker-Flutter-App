enum SyncStatus { synced, pendingSync }

class AssetEntity {
  final String id;
  final String assetName;
  final String category;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status;
  final SyncStatus syncStatus;

  const AssetEntity({
    required this.id,
    required this.assetName,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    required this.syncStatus,
  });
}