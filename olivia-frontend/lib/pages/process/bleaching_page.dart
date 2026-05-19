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
    final DashboardController controller = Get.find();

    return AppScaffold(
      title: 'Proses Bleaching',
      currentRoute: AppRoutes.bleaching,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(context),
          const SizedBox(height: 18),
          Obx(() => SensorCard(
                label: 'Suhu Bleaching',
                value: controller.suhuBleaching.value.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_auto_rounded,
                spark: controller.suhuBleaching.value > 0
                    ? controller.sparkSuhuBleaching
                    : [0.0].obs,
              )),
          const SizedBox(height: 18),
          Text('Status Aktuator (Unit 2)', style: AppText.h3(context)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  _actuatorTile(
                      'Solenoid Valve Utama', controller.bleachValve.value),
                  _actuatorTile('Pompa Inlet (P1)', controller.bleachP1.value),
                  _actuatorTile(
                      'Pompa Sirkulasi (P2)', controller.bleachP2.value),
                  _actuatorTile('Pompa Outlet (P3)', controller.bleachP3.value),
                  _actuatorTile(
                      'Heater Element 1 (H1)', controller.bleachH1.value),
                  _actuatorTile(
                      'Heater Element 2 (H2)', controller.bleachH2.value),
                  _actuatorTile(
                      'Heater Element 3 (H3)', controller.bleachH3.value),
                  _actuatorTile(
                      'Heater Element 4 (H4)', controller.bleachH4.value),
                  Card(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: const Text('Kecepatan Pengaduk (Motor)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        '${controller.bleachSpeed.value} RPM',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _actuatorTile(String title, bool isOn) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(
          isOn ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isOn ? Colors.green : Colors.red,
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
      child: Row(
        children: [
          const Icon(Icons.science_rounded, color: AppColors.teal, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahap Bleaching', style: AppText.h3(context)),
                const SizedBox(height: 4),
                const Text(
                  'Proses pencampuran material arang aktif bersama zat pemucat minyak goreng pada suhu optimal.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
