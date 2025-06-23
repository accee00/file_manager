import 'dart:typed_data';

import 'package:file_manager2/features/cloud/data/datasource/remote_data_source.dart';
import 'package:file_manager2/features/cloud/domain/repository/image_repo.dart';

class ImageRepoImpl implements ImageRepo {
  final RemoteDataSource _remoteDataSource;

  ImageRepoImpl(this._remoteDataSource);

  @override
  Future<List<Uint8List>> getImages() async {
    try {
      return await _remoteDataSource.getImages();
    } catch (e) {
      throw Exception('Failed to fetch images: $e');
    }
  }

  @override
  Future<String> uploadImage({required Uint8List image}) async {
    try {
      return await _remoteDataSource.uploadImage(image: image);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
