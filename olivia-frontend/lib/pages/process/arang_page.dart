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
    // Menemukan controller yang sudah di-init di Dashboard
    final DashboardController controller = Get.find();

    return AppScaffold(
      title: 'Proses Arang',
      currentRoute: AppRoutes.arang,
      child: ListView(
        children: [
          _hero(context),
          const SizedBox(height: 18),
          // Obx mendengarkan perubahan data dari MQTT secara otomatis
          Obx(() => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _sensorWrapper(
                      context,
                      'Suhu Pemanasan',
                      controller.arangTemp.value,
                      '°C',
                      Icons.thermostat_rounded,
                      controller.sparkArangTemp),
                  _sensorWrapper(
                      context,
                      'Volume Minyak',
                      controller.arangVol.value,
                      'L',
                      Icons.water_drop_rounded,
                      controller.sparkArangVol),
                ],
              )),
          const SizedBox(height: 20),
          _noteCard(context),
        ],
      ),
    );
  }

  Widget _sensorWrapper(BuildContext context, String label, double value,
      String unit, IconData icon, List<double> spark) {
    double width = MediaQuery.of(context).size.width;
    double cardW = width < 600 ? width : (width - 60) / 2;
    return SizedBox(
      width: cardW,
      child: SensorCard(
        label: label,
        value: value.toStringAsFixed(1),
        unit: unit,
        icon: icon,
        spark: spark,
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahap Pemanasan', style: AppText.h2(context)),
                Text('Monitoring suhu & volume awal.',
                    style: AppText.muted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text("Data diperbarui otomatis dari ESP1 (Arang)."),
    );
  }
}
