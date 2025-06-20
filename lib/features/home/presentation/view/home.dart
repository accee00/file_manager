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

  String _currentPath = '';
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
        _currentPath = startDir.path;
      });

      await _loadFiles();
    } catch (e) {
      try {
        Directory appDir = await getApplicationDocumentsDirectory();
        setState(() {
          _currentDirectory = appDir;
          _currentPath = appDir.path;
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
      _currentPath = dir.path;
    });
    await _loadFiles();
  }

  Future<void> _navigateUp() async {
    if (_currentDirectory?.parent != null) {
      await _navigateToDirectory(_currentDirectory!.parent);
    }
  }

  Future<void> _navigateToRoot() async {
    Directory root;
    if (Platform.isAndroid) {
      root = Directory('/storage/emulated/0');
      if (!await root.exists()) root = Directory('/');
    } else {
      root = await getApplicationDocumentsDirectory();
    }
    await _navigateToDirectory(root);
  }

  void _showDirectorySelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SingleChildScrollView(
        clipBehavior: Clip.hardEdge,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Color(0xFFF7F9FC),

            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ..._availableDirectories.map((dir) {
                return ListTile(
                  leading: Icon(Icons.folder, color: Colors.amber),
                  title: Text(_getDirectoryDisplayName(dir.path)),
                  subtitle: Text(dir.path),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDirectory(dir);
                  },
                );
              }),
              if (Platform.isAndroid)
                ListTile(
                  leading: Icon(Icons.smartphone, color: Colors.green),
                  title: Text('Device Root'),
                  subtitle: Text('/'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDirectory(Directory('/'));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDirectoryDisplayName(String path) {
    if (path.contains('Documents')) return 'Documents';
    if (path.contains('Download')) return 'Downloads';
    if (path.contains('Pictures')) return 'Pictures';
    if (path.contains('DCIM')) return 'Camera';
    if (path.contains('Music')) return 'Music';
    if (path.contains('Movies')) return 'Movies';
    if (path == '/storage/emulated/0') return 'Internal Storage';
    if (path == '/') return 'Root';
    if (path.contains('Android/data')) return 'App Storage';
    String name = path.split('/').last;
    return name.isEmpty ? 'Root' : name;
  }

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
      title: 'Create New Folder',
      hint: 'Folder Name',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppText.fileManager,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: IconButton(
          icon: const Icon(Icons.folder_special),
          onPressed: _showDirectorySelector,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.home), onPressed: _navigateToRoot),
          IconButton(
            icon: Icon(
              _sortAscending
                  ? Icons.sort_by_alpha
                  : Icons.sort_by_alpha_outlined,
            ),
            tooltip: _sortAscending ? 'Sort A → Z' : 'Sort Z → A',
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
              _loadFiles();
            },
          ),
          CreatePopupMenu(
            onCreateFolder: _createFolder,
            onCreateFile: _createFile,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search files or folders',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredFiles.isEmpty
                    ? Center(child: Text('No files or folders found'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _filteredFiles.length,
                        itemBuilder: (_, i) {
                          final item = _filteredFiles[i];
                          final isDir = item is Directory;
                          final name = item.path.split('/').last;
                          return ListTile(
                            leading: Icon(
                              isDir ? Icons.folder : _getFileIcon(name),
                              color: isDir ? Colors.amber : _getFileColor(name),
                            ),
                            title: Text(name),
                            subtitle: isDir
                                ? Text('Folder')
                                : FutureBuilder<FileStat>(
                                    future: item.stat(),
                                    builder: (_, snap) {
                                      if (!snap.hasData) return Text('File');
                                      final size = snap.data!.size / 1024;
                                      return Text(
                                        size > 1024
                                            ? '${(size / 1024).toStringAsFixed(1)} MB'
                                            : '${size.toStringAsFixed(1)} KB',
                                      );
                                    },
                                  ),
                            trailing: IconButton(
                              icon: Icon(Icons.more_vert),
                              onPressed: () => _showItemOptions(item),
                            ),
                            onTap: isDir
                                ? () => _navigateToDirectory(item)
                                : () => _showFilePreview(item as File),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
