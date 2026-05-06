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
                value: controller.bleachTemp.value.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_auto_rounded,
                spark: controller.sparkBleachTemp,
              )),
          const SizedBox(height: 18),
          Text('Status Aktuator (Unit 2)', style: AppText.h3(context)),
          const SizedBox(height: 10),
          Obx(() => Column(
                children: [
                  _statusTile('Solenoid Valve', controller.bleachValve.value),
                  _statusTile('Pompa 1', controller.bleachP1.value),
                  _statusTile('Heater 1', controller.bleachH1.value),
                  _statusTile('Motor AC Speed', true,
                      subtitle: "${controller.bleachSpeed.value} RPM"),
                ],
              )),
        ],
      ),
    );
  }

  Widget _statusTile(String title, bool isOn, {String? subtitle}) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
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
          const SizedBox(width: 15),
          Text('Pemurnian Minyak', style: AppText.h2(context)),
        ],
      ),
    );
  }
}
