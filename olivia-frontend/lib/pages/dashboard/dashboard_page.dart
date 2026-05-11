// lib/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _hero(context),
            const SizedBox(height: 12),

            Obx(() => _systemControl(context, controller)),
            const SizedBox(height: 12),

            Obx(() => ProgressTimeline(
                  step: controller.progressStep.value,
                  active: controller.systemOn.value,
                )),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Navigasi Proses'),
            const SizedBox(height: 12),

            // ✅ NAVIGASI KE HALAMAN PROSES
            _processNavGrid(context, controller),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Ringkasan Sensor'),
            const SizedBox(height: 12),

            Obx(() => _sensorGrid(context, controller)),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Analisis Kualitas'),
            const SizedBox(height: 12),

            Obx(() => _recommendationCard(context, controller)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ✅ SECTION BARU: Grid navigasi ke 3 halaman proses
  Widget _processNavGrid(BuildContext context, DashboardController controller) {
    return Column(
      children: [
        // Baris 1: Arang & Bleaching
        Row(
          children: [
            Expanded(
              child: Obx(() => _processCard(
                    context,
                    icon: Icons.local_fire_department_rounded,
                    title: 'Proses Arang',
                    subtitle:
                        '${controller.arangTemp.value.toStringAsFixed(1)} °C',
                    color: Colors.orange,
                    onTap: () => Get.toNamed(AppRoutes.arang),
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => _processCard(
                    context,
                    icon: Icons.science_rounded,
                    title: 'Bleaching',
                    subtitle:
                        '${controller.bleachTemp.value.toStringAsFixed(1)} °C',
                    color: Colors.blue,
                    onTap: () => Get.toNamed(AppRoutes.bleaching),
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Baris 2: Validasi (full width)
        Obx(() => _processCard(
              context,
              icon: Icons.verified_rounded,
              title: 'Validasi Kualitas',
              subtitle:
                  'Turb: ${controller.turb.value.toStringAsFixed(1)} NTU  •  Warna: ${controller.warna.value}',
              color: AppColors.teal,
              onTap: () => Get.toNamed(AppRoutes.filtrasi),
              fullWidth: true,
            )),
      ],
    );
  }

  Widget _processCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.h3(context),
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style: AppText.muted(context),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Halo, Admin', style: AppText.h1(context)),
        Text('Pantau produksi minyak hari ini.', style: AppText.muted(context)),
      ],
    );
  }

  Widget _systemControl(BuildContext context, DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: controller.systemOn.value
            ? AppColors.teal.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                controller.systemOn.value ? AppColors.teal : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.power_settings_new_rounded,
            color: controller.systemOn.value ? AppColors.teal : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Sistem', style: AppText.h3(context)),
                Text(controller.systemOn.value
                    ? 'Sistem Berjalan'
                    : 'Sistem Standby'),
              ],
            ),
          ),
          Switch(
            value: controller.systemOn.value,
            onChanged: (val) => controller.toggleSystem(),
            activeColor: AppColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _sensorGrid(BuildContext context, DashboardController controller) {
    double cardW = (MediaQuery.of(context).size.width - 44) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Arang • Suhu',
              value: controller.arangTemp.value.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.local_fire_department_rounded),
        ),
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Bleach • Suhu',
              value: controller.bleachTemp.value.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat_auto_rounded),
        ),
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Validasi • Turb',
              value: controller.turb.value.toStringAsFixed(1),
              unit: 'NTU',
              icon: Icons.blur_on_rounded),
        ),
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Minyak • Vol',
              value: controller.validasiVol.value.toStringAsFixed(1),
              unit: 'L',
              icon: Icons.opacity_rounded),
        ),
      ],
    );
  }

  Widget _recommendationCard(
      BuildContext context, DashboardController controller) {
    final isGood = controller.turb.value < 50 && controller.turb.value > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: isGood ? Colors.teal : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hasil Warna: ${controller.warna.value}',
                    style: AppText.h3(context)),
                Text(
                  isGood
                      ? 'Kualitas memenuhi standar'
                      : 'Menunggu data validasi...',
                  style: TextStyle(color: isGood ? Colors.teal : Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: AppText.h2(context));
  }
}
