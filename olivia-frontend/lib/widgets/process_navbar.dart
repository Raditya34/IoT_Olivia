import 'package:flutter/material.dart';

class ProcessNavbar extends StatelessWidget {
  final int currentIndex;

  const ProcessNavbar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/arang');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/bleaching');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/filtrasi');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
          label: "History",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: "Logout",
        ),
      ],
    );
  }
}
