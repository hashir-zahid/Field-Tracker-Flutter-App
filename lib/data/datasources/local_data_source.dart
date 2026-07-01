import 'package:hive/hive.dart';
import '../models/asset_model.dart';

class LocalDataSource {
  final Box<AssetModel> _box;
  LocalDataSource(this._box);

  Future<List<AssetModel>> getCachedAssets() async => _box.values.toList();
  
  Future<void> cacheAsset(AssetModel asset) async => _box.put(asset.id, asset);
  
  Future<List<AssetModel>> getPendingAssets() async => _box.values.where((item) => item.syncStatusStr == 'pendingSync').toList();
  
  // NEW: Method to clear the item from the local cache
  Future<void> deleteAsset(String id) async => _box.delete(id); 
}