import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../storage/auth_storage.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  Future<void> _logout(BuildContext context) async {
    // Gunakan AuthStorage agar konsisten
    await AuthStorage.clear();
    // Navigasi menggunakan GetX, menghapus semua riwayat halaman sebelumnya
    Get.offAllNamed(AppRoutes.login);
  }

  void _safeNav(BuildContext context, String route) {
    // Tutup drawer terlebih dahulu
    Navigator.pop(context);

    // Pindah halaman di frame berikutnya agar transisi mulus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (route != currentRoute) onNavigate(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                physics: const BouncingScrollPhysics(),
                children: [
                  _item(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    selected: currentRoute == AppRoutes.dashboard,
                    onTap: () => _safeNav(context, AppRoutes.dashboard),
                  ),
                  _item(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'Profil',
                    selected: currentRoute == AppRoutes.profile,
                    onTap: () => _safeNav(context, AppRoutes.profile),
                  ),
                  _item(
                    context,
                    icon: Icons.history_rounded,
                    title: 'Riwayat',
                    selected: currentRoute == AppRoutes.history,
                    onTap: () => _safeNav(context, AppRoutes.history),
                  ),
                  _item(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'Informasi Sistem',
                    selected: currentRoute == AppRoutes.info,
                    onTap: () => _safeNav(context, AppRoutes.info),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _action(
                context,
                icon: Icons.logout_rounded,
                title: 'Keluar',
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.water_drop_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OLIVIA', style: AppText.h1(context)),
              Text('Filtration System', style: AppText.slogan(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.teal.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? AppColors.tealDark : AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppText.body(context).copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppText.body(context)
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
