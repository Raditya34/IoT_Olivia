// lib/pages/dashboard/filtrasi_page.dart
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
                  _sensorBox(context, 'Turbiditas', controller.ntu.value, 'NTU',
                      Icons.blur_on),
                  _sensorBox(context, 'Viskositas', controller.viscosity.value,
                      'cP', Icons.speed),
                ],
              )),
          const SizedBox(height: 18),
          Text('Kualitas Warna Hasil Akhir', style: AppText.h3(context)),
          const SizedBox(height: 10),
          Obx(() => _warnaCard(context, controller.warnaLabel.value,
              controller.r.value, controller.g.value, controller.b.value)),
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
      child:
          Text('Validasi Kualitas Akhir Pemurnian', style: AppText.h2(context)),
    );
  }

  Widget _warnaCard(BuildContext context, String warna, int r, int g, int b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hasil Klasifikasi:', style: AppText.h3(context)),
              Flexible(
                child: Text(
                  warna,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.teal),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _rgbIndicator('R', r, Colors.red),
              _rgbIndicator('G', g, Colors.green),
              _rgbIndicator('B', b, Colors.blue),
            ],
          )
        ],
      ),
    );
  }

  Widget _rgbIndicator(String label, int value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text('$value',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
