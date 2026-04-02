import 'package:flutter/material.dart';
import 'package:iot_olivia/pages/auth/auth_gate.dart';
import 'package:iot_olivia/pages/splash/splash_page.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import '../pages/history/history_detail_page.dart';
import '../models/history_record.dart';

void main() {
  runApp(const OliviaApp());
}

class OliviaApp extends StatelessWidget {
  const OliviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.historyDetail) {
          final record = settings.arguments as HistoryRecord;
          return MaterialPageRoute(
            builder: (_) => HistoryDetailPage(record: record),
            settings: settings,
          );
        }
        return null;
      },
      title: 'OLIVIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.auth,
      home: const SplashPage(),
      routes: AppRoutes.routes,
    );
  }
}
