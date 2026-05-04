import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/progress_timeline.dart';
import '../../state/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Memanggil Controller yang sudah kita buat
    final DashboardController controller = Get.put(DashboardController());

    return AppScaffold(
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      onNavigate: (r) => Get.offAllNamed(r),
      child: ListView(
        children: [
          _hero(context),
          const SizedBox(height: 12),

          // Control Sistem (ON/OFF)
          _systemControl(context, controller),
          const SizedBox(height: 12),

          // Timeline Progress menggunakan GetX
          Obx(() => ProgressTimeline(
                step: controller.progressStep.value,
                active: controller.systemOn.value,
              )),
          const SizedBox(height: 16),

          _sectionTitle(context, 'Navigasi Proses',
              'Pilih proses untuk melihat data sensor & monitoring.'),
          const SizedBox(height: 10),
          _processGrid(context),

          const SizedBox(height: 16),
          _sectionTitle(
            context,
            'Live Snapshot',
            'Data sensor dari MQTT Railway.',
          ),
          const SizedBox(height: 10),

          // Grid Sensor dengan Data Real-time
          _snapshotGrid(context, controller),

          const SizedBox(height: 16),
          _sectionTitle(context, 'Hasil Akhir', 'Berdasarkan hasil validasi.'),
          const SizedBox(height: 10),

          // Kartu Rekomendasi Real-time
          _recommendationCard(context, controller),

          const SizedBox(height: 26),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _hero(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          gradient: LinearGradient(
            colors: [
              AppColors.teal.withOpacity(0.14),
              AppColors.orange.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: AppColors.teal.withOpacity(0.18),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OLIVIA', style: AppText.h1(context)),
                  const SizedBox(height: 4),
                  Text('Oil Filtration Automation',
                      style: AppText.muted(context)),
                  const SizedBox(height: 8),
                  Text(
                    'Monitoring proses Arang • Bleaching • Validasi dengan data sensor real-time.',
                    style: AppText.body(context)
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h2(context)),
        Text(subtitle, style: AppText.muted(context)),
      ],
    );
  }

  Widget _processGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w < 520 ? 1 : (w < 860 ? 2 : 3);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _processCard(context, cols, w,
                title: 'Arang',
                subtitle: 'Suhu • Volume',
                icon: Icons.local_fire_department_rounded,
                route: AppRoutes.arang),
            _processCard(context, cols, w,
                title: 'Bleaching',
                subtitle: 'Suhu',
                icon: Icons.science_rounded,
                route: AppRoutes.bleaching),
            _processCard(context, cols, w,
                title: 'Validasi',
                subtitle: 'Kualitas akhir',
                icon: Icons.verified_rounded,
                route: AppRoutes.filtrasi),
          ],
        );
      },
    );
  }

  Widget _processCard(
    BuildContext context,
    int cols,
    double w, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    final cardW = (w - (12 * (cols - 1))) / cols;

    return SizedBox(
      width: cardW,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3(context)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.muted(context)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _systemControl(BuildContext context, DashboardController controller) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => controller.toggleSystem(),
      child: Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: controller.systemOn.value
                  ? LinearGradient(colors: [AppColors.teal, AppColors.tealDark])
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade400]),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: controller.systemOn.value
                      ? AppColors.teal.withOpacity(0.35)
                      : Colors.black.withOpacity(0.08),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.power_settings_new_rounded,
                  size: 38,
                  color:
                      controller.systemOn.value ? Colors.white : Colors.black54,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.systemOn.value
                            ? 'SISTEM AKTIF'
                            : 'SISTEM NONAKTIF',
                        style: AppText.h3(context).copyWith(
                          color: controller.systemOn.value
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.systemOn.value
                            ? 'Monitoring berjalan'
                            : 'Tekan untuk mengaktifkan sistem',
                        style: AppText.muted(context).copyWith(
                          color: controller.systemOn.value
                              ? Colors.white70
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: controller.systemOn.value
                        ? Colors.white.withOpacity(0.20)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    controller.systemOn.value ? 'ON' : 'OFF',
                    style: AppText.chip(context).copyWith(
                      color: controller.systemOn.value
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _snapshotGrid(BuildContext context, DashboardController controller) {
    return Obx(() => LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final cols = w < 520 ? 1 : (w < 980 ? 2 : 4);
            final cardW = (w - (12 * (cols - 1))) / cols;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _sensorBox(cardW, 'Arang • Suhu', controller.arangTemp.value,
                    '°C', Icons.thermostat_rounded),
                _sensorBox(cardW, 'Arang • Volume', controller.arangVol.value,
                    'L', Icons.water_drop_rounded),
                _sensorBox(
                    cardW,
                    'Bleaching • Suhu',
                    controller.bleachTemp.value,
                    '°C',
                    Icons.thermostat_auto_rounded),
                _sensorBox(cardW, 'Validasi • Turbidity', controller.turb.value,
                    'NTU', Icons.blur_on_rounded),
              ],
            );
          },
        ));
  }

  Widget _sensorBox(
      double width, String label, double value, String unit, IconData icon) {
    return SizedBox(
      width: width,
      child: SensorCard(
        label: label,
        value: value.toStringAsFixed(1),
        unit: unit,
        icon: icon,
      ),
    );
  }

  Widget _recommendationCard(
      BuildContext context, DashboardController controller) {
    return Obx(() {
      final turb = controller.turb.value;
      final color = turb < 40
          ? AppColors.teal
          : (turb < 90 ? AppColors.orange : AppColors.danger);

      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.analytics_rounded, color: color),
              title:
                  Text('Analisis Kualitas Akhir', style: AppText.h3(context)),
              subtitle: Text(controller.warna.value,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                turb < 40
                    ? "Minyak Jernih. Layak digunakan."
                    : "Minyak Kotor. Perlu filtrasi ulang.",
                style: AppText.body(context),
              ),
            )
          ],
        ),
      );
    });
  }
}
