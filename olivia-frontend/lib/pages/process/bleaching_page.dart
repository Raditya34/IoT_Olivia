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
        ],
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
          const SizedBox(width: 14),
          Text('Tahap Bleaching', style: AppText.h2(context)),
        ],
      ),
    );
  }
}
