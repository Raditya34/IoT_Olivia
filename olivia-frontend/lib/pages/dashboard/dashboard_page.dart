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

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pemurnian Minyak Jelantah', style: AppText.h2(context)),
          const SizedBox(height: 4),
          Text('Sistem Monitoring & Kontrol Otomatis',
              style: AppText.muted(context)),
        ],
      ),
    );
  }

  Widget _systemControl(BuildContext context, DashboardController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          gradient: controller.systemOn.value
              ? AppColors.primaryGradient
              : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status Sistem',
                  style: TextStyle(color: Colors.white.withOpacity(0.9))),
              Text(
                controller.systemOn.value ? 'AKTIF BERJALAN' : 'SISTEM MATI',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Switch(
            value: controller.systemOn.value,
            onChanged: (val) => controller.toggleSystem(),
            activeColor: Colors.white,
            activeTrackColor: Colors.teal.shade300,
          ),
        ],
      ),
    );
  }

  Widget _processNavGrid(BuildContext context, DashboardController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() => _processCard(
                    context,
                    icon: Icons.local_fire_department_rounded,
                    title: 'Proses Arang',
                    subtitle: '${controller.arangTemp1.value} °C',
                    route: AppRoutes.arang,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => _processCard(
                    context,
                    icon: Icons.science_rounded,
                    title: 'Bleaching',
                    subtitle: '${controller.bleachTemp.value} °C',
                    route: AppRoutes.bleaching,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() => _processCard(
              context,
              icon: Icons.water_drop_rounded,
              title: 'Validasi Akhir',
              subtitle: 'Vol: ${controller.validasiVol.value} L',
              route: AppRoutes.filtrasi, // Validasi page
              isFullWidth: true,
            )),
      ],
    );
  }

  Widget _processCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required String route,
      bool isFullWidth = false}) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.teal, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: AppText.muted(context)),
                ],
              ),
            ),
            if (isFullWidth)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey),
          ],
        ),
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
              label: 'Suhu Arang 1',
              value: controller.arangTemp1.value.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat_rounded),
        ),
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Suhu Bleaching',
              value: controller.bleachTemp.value.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat_auto_rounded),
        ),
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Turbidity',
              value: controller.ntu.value.toStringAsFixed(1), // pakai ntu
              unit: 'NTU',
              icon: Icons.blur_on_rounded),
        ),
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Volume Akhir',
              value: controller.validasiVol.value.toStringAsFixed(1),
              unit: 'L',
              icon: Icons.opacity_rounded),
        ),
      ],
    );
  }

  Widget _recommendationCard(
      BuildContext context, DashboardController controller) {
    // Mengecek apakah Turbidity (NTU) bagus (biasanya di bawah 50 bagus untuk minyak jernih)
    final isGood = controller.ntu.value < 50 && controller.ntu.value > 0;

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
                // Menggunakan warnaLabel.value dari controller
                Text('Warna: ${controller.warnaLabel.value}',
                    style: AppText.h3(context)),
                Text(
                  isGood
                      ? 'Kekeruhan Minyak sangat baik (Memenuhi Standar)'
                      : 'Menunggu proses selesai atau kekeruhan masih tinggi...',
                  style: TextStyle(
                      color: isGood ? Colors.teal : Colors.orange,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
  }
}
