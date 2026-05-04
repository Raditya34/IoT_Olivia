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
    // Menghubungkan ke DashboardController yang sudah ada
    final DashboardController controller = Get.find();

    return AppScaffold(
      title: 'Proses Validasi',
      currentRoute: AppRoutes.filtrasi,
      child: ListView(
        children: [
          _hero(context),
          const SizedBox(height: 18),

          // Monitoring Sensor Real-time
          Obx(() => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Menambahkan monitoring Volume Minyak
                  _sensorBox(context, 'Volume Minyak',
                      controller.arangVol.value, 'L', Icons.water_drop_rounded),
                  _sensorBox(context, 'Turbidity', controller.turb.value, 'NTU',
                      Icons.blur_on_rounded),
                  _sensorBox(context, 'Viskositas', controller.visc.value, 'cP',
                      Icons.speed_rounded),
                ],
              )),
          const SizedBox(height: 12),

          // Kartu Deteksi Warna
          Obx(() => _warnaCard(context, controller.warna.value)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget pembantu untuk kotak sensor agar rapi
  Widget _sensorBox(BuildContext context, String label, double value,
      String unit, IconData icon) {
    // Menghitung lebar agar muat 2 kolom di layar HP
    double width = MediaQuery.of(context).size.width;
    double cardW = (width - 48) / 2;

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
        children: [
          const Icon(Icons.palette_rounded, color: AppColors.teal),
          const SizedBox(width: 12),
          Text('Warna Deteksi: $warna', style: AppText.h3(context)),
        ],
      ),
    );
  }
}
