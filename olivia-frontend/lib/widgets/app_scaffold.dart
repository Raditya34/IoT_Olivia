import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Tambahkan GetX
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import 'gradient_background.dart';
import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget child;
  final bool showAppBar;
  final bool showDrawer;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.showAppBar = true,
    this.showDrawer = true,
    this.actions,
    this.floatingActionButton,
    // onNavigate dihapus karena kita akan pakai GetX langsung di dalam sini
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Drawer menggunakan Get.offAllNamed agar stack bersih saat pindah menu utama
        drawer: showDrawer
            ? AppDrawer(
                currentRoute: currentRoute,
                onNavigate: (r) => Get.offAllNamed(r),
              )
            : null,
        appBar: showAppBar
            ? AppBar(
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                centerTitle: true,
                leading: showDrawer
                    ? Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      )
                    : IconButton(
                        // Jika drawer mati, munculkan tombol back otomatis
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Get.back(),
                      ),
                actions: [
                  // Gunakan rute dari AppRoutes, jangan diketik manual "/notifikasi"
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => Get.toNamed(AppRoutes.notifications),
                    tooltip: "Notifikasi",
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline_rounded),
                    onPressed: () => Get.toNamed(AppRoutes.profile),
                    tooltip: "Profile",
                  ),
                  if (actions != null) ...actions!,
                  const SizedBox(width: 6),
                ],
              )
            : null,
        floatingActionButton: floatingActionButton,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border.withOpacity(0.7)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
