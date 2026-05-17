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
                  _sensorBox(context, 'Turbidity', controller.ntu.value, 'NTU',
                      Icons.blur_on), // Diganti jadi NTU
                  _sensorBox(context, 'Viskositas', controller.freq.value, 'Hz',
                      Icons.speed), // Diganti jadi freq (Hz)
                  _sensorBox(context, 'Tegangan', controller.tegangan.value,
                      'V', Icons.bolt), // Menambah Tegangan
                ],
              )),
          const SizedBox(height: 18),
          // Menampilkan langsung string warnaLabel yang dibuat oleh Controller
          Obx(() => _warnaCard(context, controller.warnaLabel.value)),
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
          Flexible(
            child: Text(
              warna,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal,
                  fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
