import 'dart:typed_data';

abstract interface class ImageRepo {
  Future<String> uploadImage({required Uint8List image});
  Future<List<Uint8List>> getImages();
}
