import 'package:flutter/material.dart';
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
import '../pages/auth/auth_gate.dart';
import '../pages/notifikasi/notifikasi_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const historyDetail = '/history_detail';
  static const auth = '/auth';

  // ini ditambah biar dashboard gak error
  static const profile = '/profile';
  static const arang = '/arang';
  static const bleaching = '/bleaching';
  static const filtrasi = '/filtrasi';
  static const history = '/history';
  static const info = '/info';
  static const notifikasi = '/notifikasi';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),
        login: (_) => const LoginPage(),
        signup: (_) => const SignupPage(),
        dashboard: (_) => const DashboardPage(),
        profile: (_) => const ProfilePage(),
        arang: (_) => const ArangPage(),
        bleaching: (_) => const BleachingPage(),
        filtrasi: (_) => const ValidasiPage(),
        history: (_) => const HistoryPage(),
        info: (_) => const InfoPage(),
        notifikasi: (_) => const NotifikasiPage(),
      };

  static final route = <String, WidgetBuilder>{
    auth: (_) => const AuthGate(),
  };
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
