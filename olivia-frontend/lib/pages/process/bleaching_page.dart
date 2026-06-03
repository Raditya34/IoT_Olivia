// lib/pages/dashboard/bleaching_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../state/dashboard_controller.dart';

class BleachingPage extends StatelessWidget {
  const BleachingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController ctrl = Get.find();

    return AppScaffold(
      title: 'Unit Bleaching',
      currentRoute: AppRoutes.bleaching,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ─── Hero Banner ─────────────────────────────────────
          _heroBanner(context),
          const SizedBox(height: 18),

          // ─── Sensor Suhu Bleaching ────────────────────────
          _sectionHeader(context, 'Sensor Suhu Tangki Bleaching',
              Icons.thermostat_auto_rounded, Colors.redAccent),
          const SizedBox(height: 10),
          Obx(() => SensorCard(
                label: 'Suhu Pemanasan Bleaching',
                value: ctrl.suhuBleaching.value.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.device_thermostat_rounded,
                spark: ctrl.suhuBleaching.value > 0
                    ? ctrl.sparkSuhuBleaching
                    : [0.0].obs,
              )),
          const SizedBox(height: 18),

          // ─── Status Aktuator ──────────────────────────────
          _sectionHeader(context, 'Status Aktuator — Unit Bleaching',
              Icons.settings_rounded, Colors.blue),
          const SizedBox(height: 10),
          Obx(() => _actuatorPanel(context, ctrl)),
          const SizedBox(height: 18),

          // ─── Motor Pengaduk ───────────────────────────────
          _sectionHeader(context, 'Motor Pengaduk', Icons.rotate_right_rounded,
              Colors.purple),
          const SizedBox(height: 10),
          Obx(() => _motorCard(context, ctrl)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────────
  Widget _heroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.12),
            Colors.indigo.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.science_rounded, color: Colors.blue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahap Bleaching', style: AppText.h2(context)),
                const SizedBox(height: 4),
                const Text(
                  'Pencampuran arang aktif dengan minyak pada suhu optimal. '
                  'Monitor aktuator valve, pompa, dan heater secara real-time.',
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

  // ─────────────────────────────────────────────────────────────
  // PANEL AKTUATOR
  // ─────────────────────────────────────────────────────────────
  Widget _actuatorPanel(BuildContext context, DashboardController ctrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Solenoid Valve
          _actuatorRow(
            'Solenoid Valve Utama',
            'Mengatur aliran minyak masuk tangki bleaching',
            Icons.toggle_on_rounded,
            ctrl.bleachValve.value,
            Colors.blueAccent,
          ),
          const Divider(height: 16, thickness: 0.5),

          // Pompa
          _actuatorRow(
            'Pompa Inlet (P1)',
            'Memompa minyak dari tangki arang ke bleaching',
            Icons.arrow_circle_right_rounded,
            ctrl.bleachP1.value,
            Colors.blue,
          ),
          const Divider(height: 16, thickness: 0.5),
          _actuatorRow(
            'Pompa Sirkulasi (P2)',
            'Mensirkulasikan campuran minyak & arang aktif',
            Icons.loop_rounded,
            ctrl.bleachP2.value,
            Colors.indigo,
          ),
          const Divider(height: 16, thickness: 0.5),
          _actuatorRow(
            'Pompa Outlet (P3)',
            'Mengalirkan minyak ke unit validasi akhir',
            Icons.arrow_circle_left_rounded,
            ctrl.bleachP3.value,
            Colors.deepPurple,
          ),
          const Divider(height: 16, thickness: 0.5),

          // Heater
          _heaterGroupRow(ctrl),
        ],
      ),
    );
  }

  Widget _actuatorRow(
    String title,
    String subtitle,
    IconData icon,
    bool isOn,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                isOn ? color.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isOn ? color : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOn
                ? Colors.teal.withOpacity(0.1)
                : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isOn ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOn ? Colors.teal : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  // Heater H1–H4 dalam satu row group
  Widget _heaterGroupRow(DashboardController ctrl) {
    final heaters = [
      ('H1', ctrl.bleachH1.value),
      ('H2', ctrl.bleachH2.value),
      ('H3', ctrl.bleachH3.value),
      ('H4', ctrl.bleachH4.value),
    ];
    final anyOn = heaters.any((h) => h.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: anyOn
                    ? Colors.orange.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: anyOn ? Colors.orange : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Elemen Heater (H1–H4)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  const Text('Pemanas tangki bleaching ke suhu setpoint 80°C',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 4 chip H1 H2 H3 H4
        Row(
          children: heaters.map((h) {
            final label = h.$1;
            final on = h.$2;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: on
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: on
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      on
                          ? Icons.local_fire_department_rounded
                          : Icons.power_off_rounded,
                      size: 16,
                      color: on ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(height: 3),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: on ? Colors.orange : Colors.grey)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MOTOR PENGADUK
  // ─────────────────────────────────────────────────────────────
  Widget _motorCard(BuildContext context, DashboardController ctrl) {
    final speed = ctrl.bleachSpeed.value;
    final isRunning = speed > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRunning ? Colors.purple.withOpacity(0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? Colors.purple.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isRunning
                  ? Colors.purple.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rotate_right_rounded,
              color: isRunning ? Colors.purple : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Motor Pengaduk',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  isRunning
                      ? 'Mengaduk campuran minyak & arang aktif'
                      : 'Motor dalam posisi berhenti',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$speed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isRunning ? Colors.purple : Colors.grey,
                ),
              ),
              const Text('RPM',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
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
