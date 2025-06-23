import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class RemoteDataSource {
  Future<String> uploadImage({required Uint8List image});
  Future<List<Uint8List>> getImages();
}

class RemoteDataSourceImpl extends RemoteDataSource {
  final SupabaseClient supabaseClient;
  RemoteDataSourceImpl(this.supabaseClient);

  @override
  @override
  Future<String> uploadImage({required Uint8List image}) async {
    try {
      final String fileName = 'uploads/${Uuid().v4()}.png';
      debugPrint('[File Name]:-->$fileName');
      await supabaseClient.storage
          .from('data')
          .uploadBinary(
            fileName,
            image,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false,
            ),
          );
      return fileName;
    } catch (e) {
      print(e.toString());
      throw Exception('Failed to upload image: $e');
    }
  }

  @override
  Future<List<Uint8List>> getImages() async {
    try {
      final List<FileObject> files = await supabaseClient.storage
          .from('data')
          .list(path: 'uploads');

      final futures = files.map((file) async {
        try {
          final Uint8List data = await supabaseClient.storage
              .from('data')
              .download('uploads/${file.name}');
          return data;
        } catch (e) {
          print('Failed to download ${file.name}: $e');
          return Uint8List(0);
        }
      });

      return await Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to retrieve images: $e');
    }
  }
}
