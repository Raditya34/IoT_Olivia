// lib/pages/dashboard/arang_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../state/dashboard_controller.dart';

class ArangPage extends StatelessWidget {
  const ArangPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController ctrl = Get.find();

    return AppScaffold(
      title: 'Unit Arang — Slave 1',
      currentRoute: AppRoutes.arang,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ─── Hero Banner ─────────────────────────────────────
          _heroBanner(context),
          const SizedBox(height: 20),

          // ─── Status System dari Slave 1 ───────────────────
          Obx(() => _systemStatusChip(ctrl)),
          const SizedBox(height: 20),

          // ─── Section: Sensor Suhu ─────────────────────────
          _sectionHeader(context, 'Sensor Suhu — DS18B20',
              Icons.thermostat_rounded, Colors.orange),
          const SizedBox(height: 12),

          // Suhu Pemanasan Arang (DS18B20 Index 0)
          Obx(() => SensorCard(
                label: 'Suhu Pemanasan Arang',
                value: ctrl.suhuArang.value.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_rounded,
                spark:
                    ctrl.suhuArang.value > 0 ? ctrl.sparkSuhuArang : [0.0].obs,
              )),
          const SizedBox(height: 12),

          // ─── Section: Sensor Volume ───────────────────────
          _sectionHeader(context, 'Sensor Level — HC-SR04 Ultrasonik',
              Icons.water_rounded, Colors.blue),
          const SizedBox(height: 12),

          // Volume Minyak di Tangki Arang
          Obx(() => SensorCard(
                label: 'Volume Minyak di Tangki Arang',
                value: ctrl.arangVol.value.toStringAsFixed(1),
                unit: 'L',
                icon: Icons.water_rounded,
                spark: [0.0].obs, // volume tidak butuh sparkline
              )),
          const SizedBox(height: 20),

          // ─── Info Box ─────────────────────────────────────
          _infoBox(context),
        ],
      ),
    );
  }

  Widget _heroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.deepOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahap Pemanasan Arang Aktif', style: AppText.h2(context)),
                const SizedBox(height: 4),
                const Text(
                  'Monitoring suhu pembakaran arang aktif dan level volume minyak '
                  'di tangki unit pertama secara real-time.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemStatusChip(DashboardController ctrl) {
    final isOn = ctrl.systemOn.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOn
            ? Colors.teal.withOpacity(0.08)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOn
              ? Colors.teal.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOn ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: isOn ? Colors.teal : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isOn
                ? 'Slave 1 aktif — data dikirim setiap 3 detik'
                : 'Sistem standby — sensor tetap berjalan',
            style: TextStyle(
              fontSize: 12,
              color: isOn ? Colors.teal : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.teal),
              const SizedBox(width: 6),
              Text('Keterangan Sensor',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Suhu Arang: sensor DS18B20— mengukur panas tungku arang\n'
            '• Volume Arang: sensor HC-SR04 ultrasonik — menghitung volume silinder tangki\n'
            '• Data dikirim via RS485 ke ESP32 Master dengan prefix "S1:"',
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
