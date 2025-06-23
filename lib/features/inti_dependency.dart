import 'package:file_manager2/features/cloud/data/datasource/remote_data_source.dart';
import 'package:file_manager2/features/cloud/data/repository/image_repo_impl.dart';
import 'package:file_manager2/features/cloud/domain/repository/image_repo.dart';
import 'package:file_manager2/features/cloud/domain/usecase/get_images_usecase.dart';
import 'package:file_manager2/features/cloud/domain/usecase/upload_image_usecase.dart';
import 'package:file_manager2/features/cloud/presentation/cubit/image_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final serviceLocator = GetIt.instance;
Future<void> initDependency() async {
  final supabase = await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  serviceLocator.registerLazySingleton<SupabaseClient>(() => supabase.client);

  // Remote
  serviceLocator.registerLazySingleton<RemoteDataSource>(
    () => RemoteDataSourceImpl(serviceLocator()),
  );

  // Repo
  serviceLocator.registerLazySingleton<ImageRepo>(
    () => ImageRepoImpl(serviceLocator()),
  );

  // Use Cases
  serviceLocator.registerLazySingleton(() => UploadImage(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetImages(serviceLocator()));

  // Cubit
  serviceLocator.registerFactory(
    () => ImageCubit(
      uploadImageUseCase: serviceLocator(),
      getImagesUseCase: serviceLocator(),
    ),
  );
}
