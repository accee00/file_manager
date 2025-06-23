import 'package:file_manager2/app.dart';
import 'package:file_manager2/features/inti_dependency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await initDependency();
  runApp(const MyApp());
}
