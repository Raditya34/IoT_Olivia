import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

// Import ini dihapus karena sudah tidak dipakai di main.dart:
// import 'models/history_record.dart';
// import 'pages/history/history_detail_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OliviaApp());
}

class OliviaApp extends StatelessWidget {
  const OliviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'OLIVIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),

      // Gunakan initialRoute dari AppRoutes
      initialRoute: AppRoutes.splash,

      // Cukup gunakan rute standar yang sudah kamu definisikan di AppRoutes
      // GetX akan otomatis mengonversi ini dan membawa arguments-nya dengan aman
      getPages: AppRoutes.pages,

      // Blok onGenerateRoute DIHAPUS karena GetX sudah pintar
      // membawa data (Get.arguments) antar halaman.
    );
  }
}
