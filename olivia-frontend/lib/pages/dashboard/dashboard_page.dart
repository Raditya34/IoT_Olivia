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
            // Banner Ringkasan Kualitas Warna (Hero)
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

            // 🌟 BARU: Monitoring Sensor Utama Keseluruhan Proses
            _sectionTitle(context, 'Ringkasan Monitoring Proses'),
            const SizedBox(height: 10),
            Obx(() => _processOverview(context, controller)),
            const SizedBox(height: 24),

            // Navigasi Detail Unit Kerja
            _sectionTitle(context, 'Navigasi Detail Unit'),
            const SizedBox(height: 10),
            _processNavigation(context),
            const SizedBox(height: 24),

            // 🌟 BARU: Hasil Verifikasi / Validasi Kualitas Akhir di Paling Bawah
            _sectionTitle(context, 'Hasil Verifikasi Akhir'),
            const SizedBox(height: 10),
            Obx(() => _validationResultCard(context, controller)),
          ],
        ),
      ),
    );
  }

  Widget _heroSummary(BuildContext context, DashboardController controller) {
    bool isGood = controller.ntu.value < 50 && controller.ntu.value > 0;

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

  Widget _systemControl(BuildContext context, DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sistem Utama', style: AppText.h3(context)),
              Text(
                controller.systemOn.value ? 'Sistem Aktif' : 'Sistem Non-Aktif',
                style: TextStyle(
                  color: controller.systemOn.value ? Colors.green : Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Switch(
            value: controller.systemOn.value,
            activeColor: AppColors.teal,
            onChanged: (val) => controller.toggleSystem(),
          ),
        ],
      ),
    );
  }

  Widget _processOverview(
      BuildContext context, DashboardController controller) {
    // Cek status aktif heater dari unit 2
    bool isHeaterOn = controller.bleachH1.value ||
        controller.bleachH2.value ||
        controller.bleachH3.value ||
        controller.bleachH4.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Text('Parameter Proses Berjalan', style: AppText.h3(context)),
            ],
          ),
          const Divider(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _overviewItem(
                label: 'Suhu Arang',
                value: '${controller.suhuArang.value.toStringAsFixed(1)} °C',
                icon: Icons.thermostat_rounded,
                iconColor: Colors.orange,
              ),
              _overviewItem(
                label: 'Volume Validasi',
                value: '${controller.validasiVol.value.toStringAsFixed(1)} L',
                icon: Icons.opacity_rounded,
                iconColor: Colors.blue,
              ),
              _overviewItem(
                label: 'Suhu Bleaching',
                value:
                    '${controller.suhuBleaching.value.toStringAsFixed(1)} °C',
                icon: Icons.wb_sunny_rounded,
                iconColor: Colors.redAccent,
              ),
              _overviewItem(
                label: 'Status Heater',
                value: isHeaterOn ? 'Aktif' : 'Mati',
                icon: Icons.local_fire_department_rounded,
                iconColor: isHeaterOn ? Colors.green : Colors.grey,
              ),
              _overviewItem(
                label: 'Volume Validasi',
                value: '${controller.validasiVol.value.toStringAsFixed(1)} L',
                icon: Icons.water_drop_rounded,
                iconColor: Colors.purple,
              ),
              _overviewItem(
                label: 'Kekeruhan Minyak',
                value: '${controller.ntu.value.toStringAsFixed(1)} NTU',
                icon: Icons.blur_on_rounded,
                iconColor: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _processNavigation(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _navCard(
          context,
          title: 'Arang',
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
          route: AppRoutes.filtrasi,
        ),
      ],
    );
  }

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
              radius: 22,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _validationResultCard(
      BuildContext context, DashboardController controller) {
    double ntuVal = controller.ntu.value;
    double volVal = controller.validasiVol.value;
    bool isSystemOn = controller.systemOn.value;

    String statusTitle;
    String statusDesc;
    Color statusColor;
    IconData statusIcon;

    // Evaluasi kriteria filtrasi berdasarkan data riil unit validasi akhir
    if (ntuVal < 50 && ntuVal > 0) {
      statusTitle = 'FILTRASI BERHASIL';
      statusDesc =
          'Kualitas minyak jernih dan memenuhi standar purifikasi (Kekeruhan: ${ntuVal.toStringAsFixed(1)} NTU).';
      statusColor = Colors.teal;
      statusIcon = Icons.check_circle_rounded;
    } else if (ntuVal >= 50) {
      statusTitle = 'FILTRASI GAGAL';
      statusDesc =
          'Kekeruhan minyak terlalu pekat (${ntuVal.toStringAsFixed(1)} NTU) dan di luar ambang batas aman.';
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    } else {
      if (isSystemOn) {
        statusTitle = 'SISTEM MEMPROSES';
        statusDesc =
            'Minyak sedang diolah di dalam tabung, menanti cairan turun ke penampung validasi akhir.';
        statusColor = Colors.orange;
        statusIcon = Icons.sync_rounded;
      } else if (volVal > 0) {
        statusTitle = 'PROSES SELESAI';
        statusDesc =
            'Cairan terdeteksi di unit filtrasi, namun sensor kualitas masih mengonfigurasi pembacaan.';
        statusColor = Colors.blue;
        statusIcon = Icons.info_rounded;
      } else {
        statusTitle = 'SISTEM STANDBY';
        statusDesc =
            'Sistem purifikasi dalam posisi siap. Jalankan sakelar utama untuk memulai verifikasi kualitas.';
        statusColor = Colors.grey;
        statusIcon = Icons.power_settings_new_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDesc,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
