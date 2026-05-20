import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/mqtt_service.dart'; // 🌟 WAJIB DITAMBAHKAN: Import MqttService

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 WAJIB DITAMBAHKAN: Mendaftarkan MqttService secara permanen
  // Ini memastikan MQTT berjalan di background sebagai Singleton dan tidak double connection
  Get.put(MqttService(), permanent: true);

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
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}
