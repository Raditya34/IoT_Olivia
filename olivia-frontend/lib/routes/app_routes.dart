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
import '../pages/info/info_page.dart';
import '../pages/notifikasi/notifikasi_page.dart';
import '../pages/history/history_detail_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const arang = '/arang';
  static const bleaching = '/bleaching';
  static const filtrasi = '/filtrasi';
  static const historyDetail = '/history_detail';
  static const info = '/info';
  static const notifications = '/notifikasi';
  static const history = '/history';

  // Gunakan GetPage untuk fitur GetX yang lebih maksimal
  static final pages = [
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: signup, page: () => const SignupPage()),
    GetPage(name: dashboard, page: () => const DashboardPage()),
    GetPage(name: profile, page: () => const ProfilePage()),
    GetPage(name: arang, page: () => const ArangPage()),
    GetPage(name: bleaching, page: () => const BleachingPage()),
    GetPage(name: filtrasi, page: () => const ValidasiPage()),
    GetPage(name: history, page: () => const HistoryPage()),
    GetPage(name: historyDetail, page: () => const HistoryDetailPage()),
    GetPage(name: info, page: () => const InfoPage()),
    GetPage(name: notifications, page: () => const NotifikasiPage()),
  ];
}
