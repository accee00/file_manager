import 'package:file_manager2/core/const/app_theme.dart';
import 'package:file_manager2/features/application/presentation/main_screen.dart';
import 'package:file_manager2/features/cloud/presentation/cubit/image_cubit.dart';
import 'package:file_manager2/features/inti_dependency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => serviceLocator<ImageCubit>()..fetchImages(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.appTheme,
            debugShowCheckedModeBanner: false,
            home: MainScreen(),
          ),
        );
      },
    );
  }
}
