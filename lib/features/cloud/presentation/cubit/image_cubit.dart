import 'package:bloc/bloc.dart';
import 'package:file_manager2/features/cloud/domain/usecase/get_images_usecase.dart';
import 'package:file_manager2/features/cloud/domain/usecase/upload_image_usecase.dart';
import 'package:flutter/foundation.dart';

part 'image_state.dart';

class ImageCubit extends Cubit<ImageState> {
  final UploadImage uploadImageUseCase;
  final GetImages getImagesUseCase;

  ImageCubit({required this.uploadImageUseCase, required this.getImagesUseCase})
    : super(ImageInitial());

  Future<void> upload(Uint8List image) async {
    emit(ImageLoading());
    try {
      await uploadImageUseCase(image);
      await fetchImages();
    } catch (e) {
      emit(ImageError('Upload failed: $e'));
    }
  }

  Future<void> fetchImages() async {
    emit(ImageLoading());
    try {
      final images = await getImagesUseCase();
      emit(ImageLoaded(images));
    } catch (e) {
      emit(ImageError('Fetch failed: $e'));
    }
  }
}
