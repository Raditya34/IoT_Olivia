import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Tambahkan GetX
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
    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        Get.offAllNamed(AppRoutes.login); // Pakai GetX
        return;
      }

      final api = ApiService();
      await api.get('/auth/me');

      Get.offAllNamed(AppRoutes.dashboard); // Pakai GetX
    } catch (e) {
      await AuthStorage.clear();
      Get.offAllNamed(AppRoutes.login); // Pakai GetX
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
