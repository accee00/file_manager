import 'package:flutter/material.dart';

class CreatePopupMenu extends StatelessWidget {
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateFile;

  const CreatePopupMenu({
    super.key,
    required this.onCreateFolder,
    required this.onCreateFile,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      shadowColor: Colors.grey.shade400,

      color: const Color(0xFFF7F9FC),
      onSelected: (value) {
        if (value == 'create_folder') onCreateFolder();
        if (value == 'create_file') onCreateFile();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'create_folder',
          child: Text(
            'Create Folder',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        PopupMenuItem(
          value: 'create_file',
          child: Text(
            'Create File',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
