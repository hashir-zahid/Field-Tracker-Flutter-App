import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../data/repositories/asset_repository_impl.dart';
import '../../data/models/asset_model.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/use_cases/get_assets_use_case.dart';
import '../../domain/use_cases/create_asset_use_case.dart';
import '../../domain/use_cases/sync_offline_data_use_case.dart';

// --- DEPENDENCY PROVIDERS ---

final dioProvider = Provider<Dio>((ref) => Dio());
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());
final assetBoxProvider = Provider<Box<AssetModel>>((ref) => Hive.box<AssetModel>('assets'));

final localDataSourceProvider = Provider<LocalDataSource>((ref) => LocalDataSource(ref.watch(assetBoxProvider)));
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) => RemoteDataSource(ref.watch(dioProvider)));

final assetRepositoryProvider = Provider<AssetRepositoryImpl>((ref) {
  return AssetRepositoryImpl(
    localDataSource: ref.watch(localDataSourceProvider),
    remoteDataSource: ref.watch(remoteDataSourceProvider),
    connectivity: ref.watch(connectivityProvider),
  );
});

final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return ref.watch(connectivityProvider).onConnectivityChanged;
});


// --- ASSET LIST STATE MANAGEMENT ---

class AssetListNotifier extends AsyncNotifier<List<AssetEntity>> {
  @override
  Future<List<AssetEntity>> build() async {
    return GetAssetsUseCase(ref.read(assetRepositoryProvider)).execute();
  }

  Future<void> addAsset(AssetEntity asset) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await CreateAssetUseCase(ref.read(assetRepositoryProvider)).execute(asset);
      
      // Wake up the background engine to process this new item!
      ref.read(syncProvider.notifier).wakeUpEngine();
      
      return GetAssetsUseCase(ref.read(assetRepositoryProvider)).execute();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => GetAssetsUseCase(ref.read(assetRepositoryProvider)).execute());
  }
}

final assetListProvider = AsyncNotifierProvider<AssetListNotifier, List<AssetEntity>>(AssetListNotifier.new);


// --- SMART BACKGROUND SYNC ENGINE ---

enum SyncState { idle, syncing, success, failure }

class SyncNotifier extends Notifier<SyncState> {
  Timer? _autoSyncTimer;

  @override
  SyncState build() {
    // Start hunting for a connection right when the app boots up
    _startAutoSyncLoop();

    ref.onDispose(() {
      _autoSyncTimer?.cancel();
    });

    return SyncState.idle;
  }

  void _startAutoSyncLoop() {
    // Guard against creating duplicate overlapping timers
    if (_autoSyncTimer != null && _autoSyncTimer!.isActive) return;

    print("⏱️ SYNC ENGINE: Heartbeat started. Checking connection every 15s...");
    
    // Check once immediately
    triggerSync();

    // Fire every 15 seconds until killed
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      triggerSync();
    });
  }

  Future<void> triggerSync() async {
    if (state == SyncState.syncing) return;

    final connectivityResults = await ref.read(connectivityProvider).checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      return; // Device is completely offline; skip this tick and wait for the next one
    }

    state = SyncState.syncing;
    try {
      print("🔄 AUTO-SYNC: Connection verified! Sweeping database for offline assets...");
      await SyncOfflineDataUseCase(ref.read(assetRepositoryProvider)).execute();
      state = SyncState.success;
      
      // --- THE SHUTOFF VALVE ---
      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
      print("🛑 SYNC COMPLETE: Local data is synced. Timer stopped to save battery!");

      // Update the main UI list view
      ref.read(assetListProvider.notifier).refresh();
      
    } catch (e) {
      print("❌ AUTO-SYNC FAILED: $e");
      state = SyncState.failure;
    } finally {
      // Reset state back to idle if it wasn't a total success so the loop can keep trying
      if (state != SyncState.success) {
        state = SyncState.idle;
      }
    }
  }

  // Called manually by addAsset to re-arm the syncing loop when fresh offline records arrive
  void wakeUpEngine() {
    print("⚡ ENGINE WOKEN UP: New data added, restarting heartbeat...");
    _startAutoSyncLoop();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);