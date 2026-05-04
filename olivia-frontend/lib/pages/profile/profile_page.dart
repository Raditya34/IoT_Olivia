import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart'; // Tambahkan GetX

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '-';
  String email = '-';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = (prefs.getString('user_name') ?? 'Admin User').trim();
      email = (prefs.getString('user_email') ?? 'admin@olivia.com').trim();
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Logout yang bersih, menghapus seluruh stack halaman
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profil Pengguna',
      currentRoute: AppRoutes.profile,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _header(context),
          const SizedBox(height: 24),
          _infoCard(context),
          const SizedBox(height: 24),
          _actions(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.teal,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(name, style: AppText.h2(context)),
        const SizedBox(height: 4),
        Text(email, style: AppText.muted(context)),
      ],
    );
  }

  Widget _infoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row(context, 'Role', 'Administrator'),
          const Divider(height: 24),
          _row(context, 'Status', 'Aktif'),
          const Divider(height: 24),
          _row(context, 'Versi Aplikasi', 'v1.0'),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: AppText.muted(context))),
        Text(v, style: AppText.body(context)),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Aksi', style: AppText.h3(context)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
