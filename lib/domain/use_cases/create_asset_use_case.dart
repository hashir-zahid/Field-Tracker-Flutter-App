import '../entities/asset_entity.dart';
import '../repositories/asset_repository.dart';

class CreateAssetUseCase {
  final AssetRepository repository;
  CreateAssetUseCase(this.repository);

  Future<void> execute(AssetEntity asset) => repository.createAsset(asset);
}