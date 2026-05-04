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
    // Menggunakan Get.put dengan tag atau memastikannya hanya di-init sekali
    // Ini mencegah error duplikasi state saat navigasi
    final DashboardController controller = Get.put(DashboardController());

    return AppScaffold(
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _hero(context),
          const SizedBox(height: 12),

          // Bungkus kontrol sistem dengan Obx secara spesifik
          Obx(() => _systemControl(context, controller)),
          const SizedBox(height: 12),

          // Timeline yang otomatis update
          Obx(() => ProgressTimeline(
                step: controller.progressStep.value,
                active: controller.systemOn.value,
              )),
          const SizedBox(height: 16),

          _sectionTitle(context, 'Navigasi Proses',
              'Pilih proses untuk melihat data sensor & monitoring.'),
          const SizedBox(height: 10),
          _processGrid(context),

          const SizedBox(height: 16),
          _sectionTitle(
            context,
            'Live Snapshot',
            'Data sensor real-time dari MQTT Railway.',
          ),
          const SizedBox(height: 10),

          // Grid sensor real-time
          Obx(() => _snapshotGrid(context, controller)),

          const SizedBox(height: 16),
          _sectionTitle(context, 'Hasil Akhir', 'Berdasarkan hasil validasi.'),
          const SizedBox(height: 10),

          // Kartu rekomendasi real-time
          Obx(() => _recommendationCard(context, controller)),

          const SizedBox(height: 26),
        ],
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withOpacity(0.14),
            AppColors.orange.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.surface),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OLIVIA', style: AppText.h1(context)),
                Text('Oil Filtration Automation',
                    style: AppText.muted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemControl(BuildContext context, DashboardController controller) {
    final isOn = controller.systemOn.value;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: controller.toggleSystem,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isOn
              ? LinearGradient(colors: [AppColors.teal, AppColors.tealDark])
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400]),
        ),
        child: Row(
          children: [
            Icon(Icons.power_settings_new_rounded,
                size: 38, color: isOn ? Colors.white : Colors.black54),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isOn ? 'SISTEM AKTIF' : 'SISTEM NONAKTIF',
                style: AppText.h3(context)
                    .copyWith(color: isOn ? Colors.white : Colors.black87),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOn ? 'ON' : 'OFF',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOn ? Colors.white : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h2(context)),
        Text(subtitle, style: AppText.muted(context)),
      ],
    );
  }

  Widget _processGrid(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _processCard(context, 'Arang', Icons.local_fire_department_rounded,
            AppRoutes.arang),
        _processCard(
            context, 'Bleaching', Icons.science_rounded, AppRoutes.bleaching),
        _processCard(
            context, 'Validasi', Icons.verified_rounded, AppRoutes.filtrasi),
      ],
    );
  }

  Widget _processCard(
      BuildContext context, String title, IconData icon, String route) {
    return InkWell(
      onTap: () => Get.toNamed(route), // Gunakan Get.toNamed agar lebih stabil
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2.1,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: AppText.h3(context).copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _snapshotGrid(BuildContext context, DashboardController controller) {
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
              icon: Icons.thermostat_rounded),
        ),
        SizedBox(
          width: cardW,
          child: SensorCard(
              label: 'Arang • Vol',
              value: controller.arangVol.value.toStringAsFixed(1),
              unit: 'L',
              icon: Icons.water_drop_rounded),
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
              value: controller.turb.value.toStringAsFixed(0),
              unit: 'NTU',
              icon: Icons.blur_on_rounded),
        ),
      ],
    );
  }

  Widget _recommendationCard(
      BuildContext context, DashboardController controller) {
    final isGood = controller.turb.value < 50;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status: ${controller.warna.value}',
                  style: AppText.h3(context)),
              Icon(
                isGood ? Icons.check_circle : Icons.warning_rounded,
                color: isGood ? Colors.teal : Colors.orange,
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isGood ? 'Kualitas Baik' : 'Perlu Filtrasi Ulang',
            style: TextStyle(
              color: isGood ? Colors.teal : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
