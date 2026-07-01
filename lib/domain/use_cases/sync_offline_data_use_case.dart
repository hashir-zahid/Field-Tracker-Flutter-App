import '../repositories/asset_repository.dart';

class SyncOfflineDataUseCase {
  final AssetRepository repository;
  SyncOfflineDataUseCase(this.repository);

  Future<void> execute() => repository.syncOfflineData();
}