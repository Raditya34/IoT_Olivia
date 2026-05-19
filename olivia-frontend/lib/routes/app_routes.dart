// lib/routes/app_routes.dart
import 'package:get/get.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/splash/splash_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/process/arang_page.dart';
import '../pages/process/bleaching_page.dart';
import '../pages/process/filtrasi_page.dart';
import '../pages/history/history_page.dart';
import '../pages/history/history_detail_page.dart';
import '../pages/notifikasi/notifikasi_page.dart';
import '../pages/info/info_page.dart';
import '../state/dashboard_binding.dart'; // 🌟 TAMBAHAN: Import DashboardBinding

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const arang = '/arang';
  static const bleaching = '/bleaching';
  static const filtrasi = '/filtrasi';
  static const history = '/history';
  static const historyDetail = '/history_detail';
  static const notifications = '/notifikasi';
  static const info = '/info';

  static final pages = [
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: signup, page: () => const SignupPage()),
    GetPage(
      name: dashboard,
      page: () => const DashboardPage(),
      binding: DashboardBinding(),
    ),
    GetPage(name: profile, page: () => const ProfilePage()),
    GetPage(name: arang, page: () => const ArangPage()),
    GetPage(name: bleaching, page: () => const BleachingPage()),
    GetPage(name: filtrasi, page: () => const ValidasiPage()),
    GetPage(name: history, page: () => const HistoryPage()),
    GetPage(name: historyDetail, page: () => const HistoryDetailPage()),
    GetPage(name: notifications, page: () => const NotifikasiPage()),
    GetPage(name: info, page: () => const InfoPage()),
  ];
}
