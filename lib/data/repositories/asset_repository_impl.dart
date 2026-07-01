import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../models/asset_model.dart';

class AssetRepositoryImpl implements AssetRepository {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  AssetRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  @override
  Future<List<AssetEntity>> getAssets() async {
    final List<AssetModel> combinedAssets = [];

    // 1. Fetch remote data first
    try {
      final remoteModels = await remoteDataSource.fetchRemoteAssets();
      combinedAssets.addAll(remoteModels);
    } catch (_) {
      // API unreachable, gracefully continue to fetch whatever is left in local queue
    }

    // 2. Fetch anything currently sitting in the local offline cache
    final localPending = await localDataSource.getPendingAssets();

    // 3. Merge them together for the UI, ensuring no duplicates exist 
    final existingIds = combinedAssets.map((e) => e.id).toSet();
    for (var pending in localPending) {
      if (!existingIds.contains(pending.id)) {
        combinedAssets.add(pending);
      }
    }

    return combinedAssets.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> createAsset(AssetEntity asset) async {
    final model = AssetModel.fromEntity(asset);
    final connectivityResult = await connectivity.checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      // Device is offline: Safe storage in Hive cache
      await localDataSource.cacheAsset(model.copyWith(syncStatusStr: 'pendingSync'));
    } else {
      try {
        // Device is online: Send straight to JSON server, DO NOT store locally
        await remoteDataSource.uploadAsset(model);
      } catch (e) {
        // Server Unreachable fallback: Store locally so no data is lost
        await localDataSource.cacheAsset(model.copyWith(syncStatusStr: 'pendingSync'));
      }
    }
  }

  @override
  Future<void> syncOfflineData() async {
    final pending = await localDataSource.getPendingAssets();
    
    for (var asset in pending) {
      try {
        // Send data to remote server
        await remoteDataSource.uploadAsset(asset);
        
        // REVISED REQUIREMENT: Clear the local cache upon successful API verification
        await localDataSource.deleteAsset(asset.id);
      } catch (_) {
        // Halts queue processing upon network error to prevent data loss
        rethrow; 
      }
    }
  }
}