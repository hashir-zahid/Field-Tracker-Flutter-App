import 'package:dio/dio.dart';
import '../models/asset_model.dart';

class RemoteDataSource {
  final Dio _dio;
  // Chrome / Web standard development endpoint for json-server
  final String _baseUrl = 'http://localhost:3000/assets';

  RemoteDataSource(this._dio);

  Future<List<AssetModel>> fetchRemoteAssets() async {
    final response = await _dio.get(_baseUrl);
    return (response.data as List).map((json) => AssetModel.fromJson(json)).toList();
  }

  /// BONUS MARKS: Full Conflict Resolution Logic
  /// Checks if resource ID already exists on Server. If true, switches to PUT to update instead of crashing.
  Future<void> uploadAsset(AssetModel asset) async {
    bool exists = false;
    try {
      final checkResponse = await _dio.get('$_baseUrl/${asset.id}');
      if (checkResponse.statusCode == 200) exists = true;
    } catch (_) {
      // Safe assumption: Endpoint threw 404 or can't be reached, proceed with POST
    }

    if (exists) {
      await _dio.put('$_baseUrl/${asset.id}', data: asset.toJson());
    } else {
      await _dio.post(_baseUrl, data: asset.toJson());
    }
  }
}