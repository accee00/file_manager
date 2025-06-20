import 'dart:io';
import 'package:file_manager2/features/file/presentation/widget/storage_category.dart';
import 'package:file_manager2/features/file/presentation/widget/storage_stat.dart';
import 'package:flutter/material.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageInfoScreen extends StatefulWidget {
  const StorageInfoScreen({super.key});

  @override
  State<StorageInfoScreen> createState() => _StorageInfoScreenState();
}

class _StorageInfoScreenState extends State<StorageInfoScreen> {
  double totalSpace = 0;
  double freeSpace = 0;
  double usedSpace = 0;
  bool isLoading = true;

  final Map<String, Map<String, dynamic>> categories = {};

  @override
  void initState() {
    super.initState();
    _initStorageData();
  }

  Future<void> _initStorageData() async {
    await [Permission.storage, Permission.manageExternalStorage].request();

    final diskSpace = DiskSpacePlus();
    final total = await diskSpace.getTotalDiskSpace;
    final free = await diskSpace.getFreeDiskSpace;

    totalSpace = (total ?? 0) / 1024;
    freeSpace = (free ?? 0) / 1024;
    usedSpace = totalSpace - freeSpace;

    await _calculateCategorySizes();
    setState(() => isLoading = false);
  }

  Future<void> _calculateCategorySizes() async {
    final folders = {
      "Downloads": "/storage/emulated/0/Download",
      "Camera": "/storage/emulated/0/DCIM",
      "Music": "/storage/emulated/0/Music",
      "Documents": "/storage/emulated/0/Documents",
      "App Storage": "/storage/emulated/0/Android/data",
    };

    for (final entry in folders.entries) {
      final size = await _getFolderSizeInGB(entry.value);
      categories[entry.key] = {
        "size": double.parse(size.toStringAsFixed(2)),
        "items": 0,
        "icon": _getIconForFolder(entry.key),
      };
    }
  }

  Future<double> _getFolderSizeInGB(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (var entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
      return total / (1024 * 1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  IconData _getIconForFolder(String name) {
    switch (name) {
      case "Downloads":
        return Icons.download;
      case "Camera":
        return Icons.camera_alt;
      case "Music":
        return Icons.music_note;
      case "Documents":
        return Icons.insert_drive_file;
      case "App Storage":
        return Icons.apps;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentUsed = totalSpace > 0 ? usedSpace / totalSpace : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Storage'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularPercentIndicator(
                    radius: 100,
                    lineWidth: 16,
                    percent: percentUsed.clamp(0.0, 1.0).toDouble(),
                    center: Text(
                      "${(percentUsed * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    progressColor: Colors.blueAccent,
                    backgroundColor: Colors.blue.shade100,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StorageStat(
                        title: 'Used',
                        value: "${usedSpace.toStringAsFixed(1)} GB",
                      ),
                      StorageStat(
                        title: 'Available',
                        value: "${freeSpace.toStringAsFixed(1)} GB",
                      ),
                      StorageStat(
                        title: 'Total',
                        value: "${totalSpace.toStringAsFixed(1)} GB",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.cleaning_services, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Free up space',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Go to Clean to manage and free up space',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...categories.entries.map((entry) {
                    final percent = totalSpace > 0
                        ? (entry.value["size"] as double) / totalSpace
                        : 0;
                    return StorageCategory(
                      title: entry.key,
                      count: '${entry.value["items"]} items',
                      size: '${entry.value["size"]} GB',
                      percent: percent.toDouble(),
                      icon: entry.value["icon"] as IconData,
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
