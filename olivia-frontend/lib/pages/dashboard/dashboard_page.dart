// lib/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/progress_timeline.dart';
import '../../state/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());

    return AppScaffold(
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      child: RefreshIndicator(
        onRefresh: () => controller.fetchDashboardData(),
        color: AppColors.teal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Banner Validasi Kualitas Akhir (Hero)
            Obx(() => _heroSummary(context, controller)),
            const SizedBox(height: 16),

            // Kontrol Switch On/Off Sistem Utama
            Obx(() => _systemControl(context, controller)),
            const SizedBox(height: 16),

            // Timeline Tracker Alur Kerja Purifikasi
            Obx(() => ProgressTimeline(
                  step: controller.progressStep.value,
                  active: controller.systemOn.value,
                )),
            const SizedBox(height: 24),

            // Navigasi Menu Menu Proses Utama
            _sectionTitle(context, 'Navigasi Proses'),
            const SizedBox(height: 12),
            _processNavigationGrid(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Widget Hero Banner di bagian atas untuk memantau kualitas hasil minyak secara realtime
  Widget _heroSummary(BuildContext context, DashboardController controller) {
    final isGood = controller.ntu.value < 50 && controller.ntu.value > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: isGood ? Colors.teal : Colors.orange,
            size: 32,
          ),
          const SizedBox(
              width: 16), // FIX: Menghilangkan karakter '\' pengganggu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warna: ${controller.warnaLabel.value}',
                  style: AppText.h3(context),
                ),
                const SizedBox(height: 4),
                Text(
                  isGood
                      ? 'Kekeruhan Minyak sangat baik (Memenuhi Standar)'
                      : 'Menunggu proses selesai atau kekeruhan masih tinggi...',
                  style: TextStyle(
                    color: isGood ? Colors.teal : Colors.orange,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card kontrol untuk mengaktifkan atau menonaktifkan seluruh mesin IoT
  Widget _systemControl(BuildContext context, DashboardController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status Sistem Utama', style: AppText.h3(context)),
              Text(
                controller.systemOn.value ? 'Sistem Aktif' : 'Sistem Nonaktif',
                style: TextStyle(
                  color: controller.systemOn.value ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Switch(
            value: controller.systemOn.value,
            activeColor: AppColors.teal,
            onChanged: (value) => controller.toggleSystem(),
          ),
        ],
      ),
    );
  }

  /// Sub-heading section penanda kelompok menu dashboard
  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.teal,
      ),
    );
  }

  /// Grid menu navigasi untuk mengarahkan pengguna ke detail tiap unit ESP32
  Widget _processNavigationGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _navCard(
          context,
          title: 'Tahap Arang',
          icon: Icons.local_fire_department_rounded,
          color: Colors.orange,
          route: AppRoutes.arang,
        ),
        _navCard(
          context,
          title: 'Bleaching',
          icon: Icons.science_rounded,
          color: Colors.blue,
          route: AppRoutes.bleaching,
        ),
        _navCard(
          context,
          title: 'Validasi',
          icon: Icons.verified_rounded,
          color: Colors.purple,
          route: AppRoutes
              .filtrasi, // Sesuai dengan rute halaman ValidasiPage Anda
        ),
      ],
    );
  }

  /// Komponen pembangun tombol navigasi unit
  Widget _navCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
