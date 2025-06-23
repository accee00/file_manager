import 'dart:typed_data';

import 'package:file_manager2/features/cloud/domain/repository/image_repo.dart';

class GetImages {
  final ImageRepo repo;

  GetImages(this.repo);

  Future<List<Uint8List>> call() async {
    return await repo.getImages();
  }
}
