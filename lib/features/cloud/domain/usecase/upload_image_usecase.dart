import 'dart:typed_data';

import 'package:file_manager2/features/cloud/domain/repository/image_repo.dart';

class UploadImage {
  final ImageRepo repo;

  UploadImage(this.repo);

  Future<String> call(Uint8List image) async {
    return await repo.uploadImage(image: image);
  }
}
