import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
  }

  void _safeNav(BuildContext context, String route) {
    // close drawer dulu
    Navigator.pop(context);

    // push di frame berikutnya (anti _debugLocked & anti blank)
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: [
                  _item(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Dashboard',
                    route: AppRoutes.dashboard,
                    onTap: () => _safeNav(context, AppRoutes.dashboard),
                  ),
                  _item(
                    context,
                    icon: Icons.history_rounded,
                    title: 'History',
                    route: AppRoutes.history,
                    onTap: () => _safeNav(context, AppRoutes.history),
                  ),
                  _item(
                    context,
                    icon: Icons.info_rounded,
                    title: 'Info',
                    route: AppRoutes.info,
                    onTap: () => _safeNav(context, AppRoutes.info),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 8),
                  _item(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    route: AppRoutes.profile,
                    onTap: () => _safeNav(context, AppRoutes.profile),
                  ),
                  _action(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: () async {
                      Navigator.pop(context);
                      await _logout(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OLIVIA', style: AppText.h2(context)),
                const SizedBox(height: 2),
                Text('Oil Filtration Automation',
                    style: AppText.caption(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required VoidCallback onTap,
  }) {
    final selected = currentRoute == route;

    return Material(
      color: selected ? AppColors.teal.withOpacity(0.10) : Colors.transparent,
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
              Expanded(child: Text(title, style: AppText.body(context))),
            ],
          ),
        ),
      ),
    );
  }
}
