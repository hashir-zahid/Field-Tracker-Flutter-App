import '../entities/asset_entity.dart';

abstract class AssetRepository {
  Future<List<AssetEntity>> getAssets();
  Future<void> createAsset(AssetEntity asset);
  Future<void> syncOfflineData();
}