import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../storage/auth_storage.dart';
import '../../../services/api_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final loggedIn = await AuthStorage.isLoggedIn();
    final token = await AuthStorage.getToken();
    final hasToken = loggedIn && token != null && token.isNotEmpty;

    if (!mounted) return;

    if (!hasToken) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // ✅ V2: Validasi token dengan /auth/me
    try {
      final api = ApiService();
      final res = await api.get('/auth/me'); // pastikan endpoint ini sudah ada

      // Kalau sukses (200), user valid → masuk dashboard
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      // Kalau 401/invalid token/failed request → bersihin session
      await AuthStorage.clear();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
