import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void safeNav(BuildContext context, String route, {Object? args}) {
    // Tutup drawer kalau sedang kebuka (kalau gak kebuka, gak masalah)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Push di frame berikutnya supaya gak nabrak _debugLocked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(route, arguments: args);
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = (prefs.getString('user_name') ?? '-').trim();
      email = (prefs.getString('user_email') ?? '-').trim();
      if (name.isEmpty) name = '-';
      if (email.isEmpty) email = '-';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      currentRoute: AppRoutes.profile,
      onNavigate: (r) => _navigate(context, r),
      child: ListView(
        children: [
          _header(context),
          const SizedBox(height: 12),
          _infoCard(context),
          const SizedBox(height: 12),
          _actions(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final initials =
        (name.isNotEmpty && name != '-') ? name.trim()[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppColors.modernGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppText.h2(context)
                    .copyWith(color: Colors.white, fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.h2(context)),
                const SizedBox(height: 4),
                Text(email, style: AppText.muted(context)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _badge(context, 'OPERATOR', AppColors.tealDark),
                    _badge(context, 'OLIVIA SYSTEM', AppColors.orangeDeep),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: AppText.chip(context).copyWith(color: color),
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Akun', style: AppText.h3(context)),
          const SizedBox(height: 10),
          _row(context, 'Nama', name),
          const Divider(height: 18, color: AppColors.divider),
          _row(context, 'Email', email),
          const Divider(height: 18, color: AppColors.divider),
          _row(context, 'Versi App', 'v1.0'),
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
