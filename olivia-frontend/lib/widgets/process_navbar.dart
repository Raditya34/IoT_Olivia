import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';

class ProcessNavbar extends StatelessWidget {
  final int currentIndex;

  const ProcessNavbar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    // Menggunakan Get.offNamed agar tidak menumpuk stack memori
    switch (index) {
      case 0:
        Get.offNamed(AppRoutes.arang);
        break;
      case 1:
        Get.offNamed(AppRoutes.bleaching);
        break;
      case 2:
        Get.offNamed(AppRoutes.filtrasi);
        break;
      case 3:
        Get.offNamed(AppRoutes.history);
        break;
      case 4:
        Get.offAllNamed(AppRoutes.dashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => _onTap(context, i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.factory),
          label: "Arang",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_fire_department),
          label: "Bleaching",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: "Filtrasi",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: "Riwayat",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
      ],
    );
  }
}
