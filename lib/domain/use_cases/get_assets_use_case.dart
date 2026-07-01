import '../entities/asset_entity.dart';
import '../repositories/asset_repository.dart';

class GetAssetsUseCase {
  final AssetRepository repository;
  GetAssetsUseCase(this.repository);

  Future<List<AssetEntity>> execute() => repository.getAssets();
}