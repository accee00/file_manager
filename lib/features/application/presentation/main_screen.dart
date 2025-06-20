import 'package:file_manager2/core/const/app_color.dart';
import 'package:file_manager2/core/const/app_images.dart';
import 'package:file_manager2/core/const/app_text.dart';
import 'package:file_manager2/features/file/presentation/view/new.dart';
import 'package:file_manager2/features/home/presentation/view/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;
  List<Widget> body = [
    HomeScreen(),
    StorageInfoScreen(),
    Center(child: Text('Cloud')),
    Center(child: Text('Clean')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (value) {
          setState(() {
            index = value;
          });
        },
        selectedItemColor: AppColor.primarySelectionColor,
        showSelectedLabels: true,
        items: [
          _buildNavBarItem(imgPath: AppImages.home, label: AppText.home),
          _buildNavBarItem(imgPath: AppImages.file, label: AppText.file),
          _buildNavBarItem(imgPath: AppImages.cloud, label: AppText.cloud),
          _buildNavBarItem(imgPath: AppImages.clean, label: AppText.clean),
        ],
      ),
      body: body[index],
    );
  }

  BottomNavigationBarItem _buildNavBarItem({
    required String imgPath,
    required String label,
  }) {
    return BottomNavigationBarItem(
      activeIcon: SvgPicture.asset(
        imgPath,
        colorFilter: ColorFilter.mode(
          AppColor.primarySelectionColor,
          BlendMode.srcIn,
        ),
      ),
      label: label,
      icon: SvgPicture.asset(imgPath),
    );
  }
}
