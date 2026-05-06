import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../state/dashboard_controller.dart';

class ValidasiPage extends StatelessWidget {
  const ValidasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find();

    return AppScaffold(
      title: 'Proses Validasi',
      currentRoute: AppRoutes.filtrasi,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(context),
          const SizedBox(height: 18),
          Obx(() => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _sensorBox(context, 'Volume Akhir',
                      controller.validasiVol.value, 'L', Icons.water_drop),
                  _sensorBox(context, 'Turbidity', controller.turb.value, 'NTU',
                      Icons.blur_on),
                  _sensorBox(context, 'Viskositas', controller.visc.value, 'cP',
                      Icons.speed),
                ],
              )),
          const SizedBox(height: 18),
          Obx(() => _warnaCard(context, controller.warna.value)),
        ],
      ),
    );
  }

  Widget _sensorBox(BuildContext context, String label, double value,
      String unit, IconData icon) {
    double cardW = (MediaQuery.of(context).size.width - 48) / 2;
    return SizedBox(
      width: cardW,
      child: SensorCard(
          label: label,
          value: value.toStringAsFixed(1),
          unit: unit,
          icon: icon),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border)),
      child: Text('Validasi Kualitas Akhir', style: AppText.h2(context)),
    );
  }

  Widget _warnaCard(BuildContext context, String warna) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Hasil Warna:', style: AppText.h3(context)),
          Text(warna,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal)),
        ],
      ),
    );
  }
}
