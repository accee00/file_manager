// ignore_for_file: deprecated_member_use

import 'package:file_manager2/core/const/app_text.dart';
import 'package:file_manager2/core/utils/custom_snackBar.dart';
import 'package:file_manager2/features/home/presentation/view/image_viewer.dart';
import 'package:file_manager2/features/home/presentation/view/pdf_viewer_screen.dart';
import 'package:file_manager2/features/home/presentation/widgets/pop_up_menu.dart';
import 'package:file_manager2/features/home/presentation/widgets/show_input_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _filteredFiles = [];
  Directory? _currentDirectory;
  bool _isLoading = true;
  bool _sortAscending = true;

  List<Directory> _availableDirectories = [];

  @override
  void initState() {
    super.initState();
    _initializeDirectory();
    _searchController.addListener(_filterFiles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> _countItems(Directory dir) async {
    try {
      final List<FileSystemEntity> items = await dir.list().toList();
      return items.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    try {
      int size = 0;
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (e) {
            // Skip files that can't be read
            continue;
          }
        }
      }
      return size;
    } catch (_) {
      return 0;
    }
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  Future<void> _initializeDirectory() async {
    try {
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      await _getAvailableDirectories();

      Directory startDir;
      if (Platform.isIOS) {
        startDir = await getApplicationDocumentsDirectory();
      } else {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          startDir = Directory('/storage/emulated/0');
          if (!await startDir.exists()) {
            startDir = externalDir;
          }
        } else {
          startDir = await getApplicationDocumentsDirectory();
        }
      }

      setState(() {
        _currentDirectory = startDir;
      });

      await _loadFiles();
    } catch (e) {
      try {
        Directory appDir = await getApplicationDocumentsDirectory();
        setState(() {
          _currentDirectory = appDir;
        });
        await _loadFiles();
      } catch (e2) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFilePreview(File file) {
    final name = file.path.toLowerCase();

    if (name.endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerScreen(path: file.path)),
      );
    } else if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImageViewerScreen(path: file.path)),
      );
    } else {}
  }

  Future<void> _requestAndroidPermissions() async {
    if (Platform.isAndroid) {
      await [Permission.storage, Permission.manageExternalStorage].request();
    }
  }

  Future<void> _getAvailableDirectories() async {
    _availableDirectories.clear();
    try {
      Directory appDocs = await getApplicationDocumentsDirectory();
      _availableDirectories.add(appDocs);

      Directory? externalStorage = await getExternalStorageDirectory();
      if (externalStorage != null) {
        _availableDirectories.add(externalStorage);
      }

      if (Platform.isAndroid) {
        List<String> commonPaths = [
          '/storage/emulated/0',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Movies',
          '/sdcard',
        ];
        for (String path in commonPaths) {
          Directory dir = Directory(path);
          if (await dir.exists()) {
            _availableDirectories.add(dir);
          }
        }
      }

      if (Platform.isIOS) {
        try {
          Directory? downloads = await getDownloadsDirectory();
          if (downloads != null) _availableDirectories.add(downloads);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _loadFiles() async {
    if (_currentDirectory == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      List<FileSystemEntity> files = [];
      try {
        files = _currentDirectory!.listSync();
      } catch (_) {
        files = _availableDirectories.cast<FileSystemEntity>();
      }
      files.sort((a, b) {
        bool aIsDir = a is Directory;
        bool bIsDir = b is Directory;

        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;

        final aName = a.path.split('/').last.toLowerCase();
        final bName = b.path.split('/').last.toLowerCase();
        return _sortAscending ? aName.compareTo(bName) : bName.compareTo(aName);
      });

      setState(() {
        _files = files;
        _filteredFiles = files;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterFiles() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = _files;
      } else {
        _filteredFiles = _files.where((file) {
          String name = file.path.split('/').last.toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _navigateToDirectory(Directory dir) async {
    setState(() {
      _currentDirectory = dir;
    });
    await _loadFiles();
  }

  Future<void> _navigateUp() async {
    if (_currentDirectory?.parent != null) {
      await _navigateToDirectory(_currentDirectory!.parent);
    }
  }

  // Future<void> _navigateToRoot() async {
  //   Directory root;
  //   if (Platform.isAndroid) {
  //     root = Directory('/storage/emulated/0');
  //     if (!await root.exists()) root = Directory('/');
  //   } else {
  //     root = await getApplicationDocumentsDirectory();
  //   }
  //   await _navigateToDirectory(root);
  // }

  // String _getDirectoryDisplayName(String path) {
  //   if (path.contains('Documents')) return 'Documents';
  //   if (path.contains('Download')) return 'Downloads';
  //   if (path.contains('Pictures')) return 'Pictures';
  //   if (path.contains('DCIM')) return 'Camera';
  //   if (path.contains('Music')) return 'Music';
  //   if (path.contains('Movies')) return 'Movies';
  //   if (path == '/storage/emulated/0') return 'Internal Storage';
  //   if (path == '/') return 'Root';
  //   if (path.contains('Android/data')) return 'App Storage';
  //   String name = path.split('/').last;
  //   return name.isEmpty ? 'Root' : name;
  // }

  Future<void> _createFolder() async {
    String? name = await CustomInputDialog.show(
      context,
      title: 'Create Folder',
      hint: 'Enter folder name:',
    );
    if (name != null && name.isNotEmpty) {
      try {
        Directory newDir = Directory('${_currentDirectory!.path}/$name');
        await newDir.create();
        await _loadFiles();
        if (mounted) {
          showCustomSnackBar(context, 'Folder $name is created!!');
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(context, 'Error creating folder ${e.toString()}');
        }
      }
    }
  }

  Future<void> _createFile() async {
    String? name = await CustomInputDialog.show(
      context,
      title: 'Create New File',
      hint: 'File Name (with extension)',
    );
    if (name != null && name.isNotEmpty) {
      try {
        File file = File('${_currentDirectory!.path}/$name');
        await file.writeAsString('');
        await _loadFiles();
        if (mounted) {
          showCustomSnackBar(context, 'File $name is created!!');
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(context, 'Error creating file ${e.toString()}');
        }
      }
    }
  }

  Future<void> _deleteItem(FileSystemEntity item) async {
    bool? confirm = await _showConfirmDialog(
      'Delete ${item is Directory ? 'Folder' : 'File'}',
      'Are you sure you want to delete "${item.path.split('/').last}"?',
    );
    if (confirm == true) {
      try {
        await item.delete(recursive: true);
        await _loadFiles();
        if (mounted) {
          showCustomSnackBar(context, 'Item deleted!!');
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(context, 'Error!!');
        }
      }
    }
  }

  Future<void> _renameItem(FileSystemEntity item) async {
    String currentName = item.path.split('/').last;
    String? newName = await _showInputDialog(
      'Rename',
      'Enter new name:',
      currentName,
    );
    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        String newPath = '${item.parent.path}/$newName';
        await item.rename(newPath);
        await _loadFiles();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Renamed')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<String?> _showInputDialog(
    String title,
    String hint, [
    String? initialValue,
  ]) async {
    TextEditingController controller = TextEditingController(
      text: initialValue ?? '',
    );
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(FileSystemEntity item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _renameItem(item);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String name) {
    String ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
        return Icons.video_file;
      case 'mp3':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String name) {
    String ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      case 'mp4':
        return Colors.red;
      case 'mp3':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'txt':
        return Colors.blue;
      case 'zip':
      case 'rar':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppText.fileManager,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CreatePopupMenu(
              onCreateFolder: _createFolder,
              onCreateFile: _createFile,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search files and folders',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_currentDirectory?.parent != null)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _navigateUp,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back_rounded,
                                      size: 20,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _currentDirectory?.path.split('/').last ?? 'Root',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _sortAscending
                                  ? Icons.sort_by_alpha_rounded
                                  : Icons.sort_by_alpha_outlined,
                              size: 22,
                            ),
                            tooltip: _sortAscending
                                ? 'Sort A → Z'
                                : 'Sort Z → A',
                            color: colorScheme.onSurfaceVariant,
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                              });
                              _loadFiles();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading files...',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredFiles.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No files or folders found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This directory is empty',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.separated(
                  itemCount: _filteredFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = _filteredFiles[i];
                    final isDir = item is Directory;
                    final name = item.path.split('/').last;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isDir
                              ? () => _navigateToDirectory(item)
                              : () => _showFilePreview(item as File),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDir
                                        ? Colors.amber.withOpacity(0.15)
                                        : _getFileColor(name).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isDir
                                        ? Icons.folder_rounded
                                        : _getFileIcon(name),
                                    size: 28,
                                    color: isDir
                                        ? Colors.amber.shade700
                                        : _getFileColor(name),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<Map<String, dynamic>>(
                                        future: _getItemInfo(item, isDir),
                                        builder: (_, snapshot) {
                                          if (!snapshot.hasData) {
                                            return Text(
                                              'Loading...',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            );
                                          }

                                          final info = snapshot.data!;
                                          final size = info['size'] as String;
                                          final count = info['count'] as int?;

                                          return Text(
                                            isDir
                                                ? '$count items • $size'
                                                : size,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 20,
                                    ),
                                    color: colorScheme.onSurfaceVariant,
                                    onPressed: () => _showItemOptions(item),
                                    tooltip: 'More options',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getItemInfo(
    FileSystemEntity item,
    bool isDir,
  ) async {
    try {
      if (isDir) {
        final directory = item as Directory;
        final itemCount = await _countItems(directory);
        final size = await _getDirectorySize(directory);
        return {'count': itemCount, 'size': _formatSize(size)};
      } else {
        final file = item as File;
        final size = await file.length();
        return {'count': null, 'size': _formatSize(size)};
      }
    } catch (e) {
      return {'count': isDir ? 0 : null, 'size': '0 B'};
    }
  }
}
