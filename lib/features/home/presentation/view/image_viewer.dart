import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatelessWidget {
  final String path;

  const ImageViewerScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(path.split('/').last)),
      body: PhotoView(
        enableRotation: true,
        backgroundDecoration: BoxDecoration(color: Colors.white),
        imageProvider: FileImage(File(path)),
      ),
    );
  }
}
