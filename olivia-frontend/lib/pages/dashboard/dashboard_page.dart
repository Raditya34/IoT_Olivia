// lib/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/progress_timeline.dart';
import '../../state/dashboard_controller.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();
    return AppScaffold(
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      child: RefreshIndicator(
        onRefresh: () => ctrl.fetchInitialData(),
        color: AppColors.teal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ─── Hero Status Kualitas ──────────────────────────
            Obx(() => _heroQuality(context, ctrl)),
            const SizedBox(height: 14),

            // ─── Kontrol ON/OFF Sistem ────────────────────────
            Obx(() => _systemControlCard(context, ctrl)),
            const SizedBox(height: 14),

            // ─── Progress Timeline ────────────────────────────
            Obx(() => ProgressTimeline(
                  step: ctrl.progressStep.value,
                  active: ctrl.systemOn.value,
                )),
            const SizedBox(height: 22),

            // ─── Ringkasan Sensor ─────────────────────────────
            _sectionHeader(
                context, 'Ringkasan Parameter Sensor', Icons.sensors_rounded),
            const SizedBox(height: 10),
            Obx(() => _sensorSummaryGrid(context, ctrl)),
            const SizedBox(height: 22),

            // ─── Navigasi Unit ────────────────────────────────
            _sectionHeader(
                context, 'Detail Per Unit Proses', Icons.grid_view_rounded),
            const SizedBox(height: 10),
            _unitNavigationRow(context),
            const SizedBox(height: 22),

            // ─── Hasil Validasi Akhir ─────────────────────────
            _sectionHeader(
                context, 'Hasil Validasi Kualitas', Icons.verified_rounded),
            const SizedBox(height: 10),
            Obx(() => _validationCard(context, ctrl)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO: STATUS KUALITAS MINYAK
  // ─────────────────────────────────────────────────────────────
  Widget _heroQuality(BuildContext context, DashboardController ctrl) {
    final ntuVal = ctrl.ntu.value;
    final bool hasData = ntuVal > 0;
    final bool isGood = hasData && ntuVal < 50;

    Color bgColor;
    Color accentColor;
    IconData icon;
    String title;
    String subtitle;

    if (!hasData) {
      bgColor = AppColors.surface;
      accentColor = Colors.grey;
      icon = Icons.hourglass_empty_rounded;
      title = 'Menunggu Data Sensor...';
      subtitle = 'Hidupkan sistem untuk memulai pembacaan kualitas minyak';
    } else if (isGood) {
      bgColor = Colors.teal.withOpacity(0.08);
      accentColor = Colors.teal;
      icon = Icons.check_circle_rounded;
      title = ctrl.warnaLabel.value;
      subtitle =
          'Kekeruhan: ${ntuVal.toStringAsFixed(1)} NTU — Memenuhi standar purifikasi';
    } else {
      bgColor = Colors.orange.withOpacity(0.08);
      accentColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
      title = ctrl.warnaLabel.value;
      subtitle =
          'Kekeruhan: ${ntuVal.toStringAsFixed(1)} NTU — Masih memerlukan proses';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: accentColor)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          // Fuzzy score badge (jika ada)
          if (ctrl.kelayakan.value > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${ctrl.kelayakan.value.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: accentColor),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SYSTEM CONTROL CARD
  // ─────────────────────────────────────────────────────────────
  Widget _systemControlCard(BuildContext context, DashboardController ctrl) {
    final isOn = ctrl.systemOn.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOn ? Colors.teal.withOpacity(0.4) : AppColors.border,
          width: isOn ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isOn
                  ? Colors.teal.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOn ? Icons.power_rounded : Icons.power_off_rounded,
              color: isOn ? Colors.teal : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kontrol Sistem Utama', style: AppText.h3(context)),
                const SizedBox(height: 2),
                Text(
                  isOn
                      ? 'Sistem sedang berjalan aktif'
                      : 'Sistem dalam posisi standby',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn ? Colors.teal : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOn,
            activeColor: AppColors.teal,
            onChanged: (val) => ctrl.toggleSystem(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SENSOR SUMMARY GRID (6 parameter utama)
  // ─────────────────────────────────────────────────────────────
  Widget _sensorSummaryGrid(BuildContext context, DashboardController ctrl) {
    final bool heaterOn = ctrl.bleachH1.value ||
        ctrl.bleachH2.value ||
        ctrl.bleachH3.value ||
        ctrl.bleachH4.value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Baris 1
          Row(children: [
            Expanded(
              child: _paramTile(
                label: 'Suhu Pemanasan\nArang',
                value: '${ctrl.suhuArang.value.toStringAsFixed(1)}',
                unit: '°C',
                icon: Icons.thermostat_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _paramTile(
                label: 'Volume Minyak\nTangki Arang',
                value: '${ctrl.arangVol.value.toStringAsFixed(1)}',
                unit: 'L',
                icon: Icons.water_rounded,
                color: Colors.blue,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Baris 2
          Row(children: [
            Expanded(
              child: _paramTile(
                label: 'Suhu Tangki\nBleaching',
                value: '${ctrl.suhuBleaching.value.toStringAsFixed(1)}',
                unit: '°C',
                icon: Icons.device_thermostat_rounded,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _paramTile(
                label: 'Elemen Heater',
                value: heaterOn ? 'Aktif' : 'Mati',
                unit: '',
                icon: Icons.local_fire_department_rounded,
                color: heaterOn ? Colors.green : Colors.grey,
                isStatus: true,
                statusOn: heaterOn,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Baris 3
          Row(children: [
            Expanded(
              child: _paramTile(
                label: 'Volume Minyak\nTangki Validasi',
                value: '${ctrl.validasiVol.value.toStringAsFixed(1)}',
                unit: 'L',
                icon: Icons.science_rounded,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _paramTile(
                label: 'Kekeruhan\n(Turbiditas)',
                value: '${ctrl.ntu.value.toStringAsFixed(1)}',
                unit: 'NTU',
                icon: Icons.blur_on_rounded,
                color: Colors.teal,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _paramTile({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    bool isStatus = false,
    bool statusOn = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey, height: 1.3),
                  maxLines: 2,
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isStatus
                              ? (statusOn ? Colors.green : Colors.grey)
                              : Colors.black87,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: ' $unit',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // NAVIGASI UNIT (3 kartu horizontal)
  // ─────────────────────────────────────────────────────────────
  Widget _unitNavigationRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _unitCard(
            context,
            title: 'Unit Arang',
            subtitle: 'Suhu & Volume',
            icon: Icons.local_fire_department_rounded,
            color: Colors.orange,
            route: AppRoutes.arang,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _unitCard(
            context,
            title: 'Bleaching',
            subtitle: 'Aktuator & Suhu',
            icon: Icons.science_rounded,
            color: Colors.blue,
            route: AppRoutes.bleaching,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _unitCard(
            context,
            title: 'Validasi',
            subtitle: 'Kualitas Akhir',
            icon: Icons.verified_rounded,
            color: Colors.purple,
            route: AppRoutes.filtrasi,
          ),
        ),
      ],
    );
  }

  Widget _unitCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VALIDATION RESULT CARD
  // ─────────────────────────────────────────────────────────────
  Widget _validationCard(BuildContext context, DashboardController ctrl) {
    final ntuVal = ctrl.ntu.value;
    final volVal = ctrl.validasiVol.value;
    final isOn = ctrl.systemOn.value;
    final kelayakan = ctrl.kelayakan.value;

    String title;
    String desc;
    Color color;
    IconData icon;

    if (kelayakan > 85 || (ntuVal > 0 && ntuVal < 50)) {
      title = 'FILTRASI BERHASIL';
      desc =
          'Kualitas minyak sangat baik. Kekeruhan ${ntuVal.toStringAsFixed(1)} NTU, '
          'skor kelayakan ${kelayakan.toStringAsFixed(0)}/100.';
      color = Colors.teal;
      icon = Icons.check_circle_rounded;
    } else if (kelayakan > 0 && kelayakan <= 41) {
      title = 'TIDAK MEMENUHI STANDAR';
      desc = 'Kualitas minyak belum memenuhi standar. '
          'Skor kelayakan: ${kelayakan.toStringAsFixed(0)}/100. '
          'NTU: ${ntuVal.toStringAsFixed(1)}.';
      color = Colors.red;
      icon = Icons.cancel_rounded;
    } else if (ntuVal >= 50) {
      title = 'KEKERUHAN MELEBIHI BATAS';
      desc =
          'Turbiditas ${ntuVal.toStringAsFixed(1)} NTU melebihi ambang batas. '
          'Proses purifikasi perlu diulang.';
      color = Colors.red;
      icon = Icons.cancel_rounded;
    } else if (kelayakan > 41 && kelayakan <= 75) {
      title = 'KURANG LAYAK';
      desc = 'Minyak kurang layak. Skor ${kelayakan.toStringAsFixed(0)}/100. '
          'Pertimbangkan purifikasi ulang.';
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else if (isOn) {
      title = 'SISTEM MEMPROSES';
      desc =
          'Minyak sedang diolah. Menunggu cairan turun ke tangki validasi akhir.';
      color = Colors.orange;
      icon = Icons.sync_rounded;
    } else if (volVal > 0) {
      title = 'PROSES SELESAI';
      desc =
          'Cairan terdeteksi di tangki validasi. Sensor kualitas masih mengonfigurasi.';
      color = Colors.blue;
      icon = Icons.info_rounded;
    } else {
      title = 'SISTEM STANDBY';
      desc =
          'Sistem siap. Aktifkan saklar utama untuk memulai siklus purifikasi.';
      color = Colors.grey;
      icon = Icons.power_settings_new_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.3)),
                const SizedBox(height: 5),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey, height: 1.4)),
                // Progress bar kelayakan (jika ada data)
                if (kelayakan > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Kelayakan: ',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: kelayakan / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${kelayakan.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
