// lib/pages/dashboard/filtrasi_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../state/dashboard_controller.dart';

class ValidasiPage extends StatelessWidget {
  const ValidasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController ctrl = Get.find();

    return AppScaffold(
      title: 'Validasi Kualitas Akhir',
      currentRoute: AppRoutes.filtrasi,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ─── Hero Banner ─────────────────────────────────────
          _heroBanner(context),
          const SizedBox(height: 18),

          // ─── Fuzzy Logic Score (Highlight Utama) ─────────
          Obx(() => _fuzzyScoreCard(context, ctrl)),
          const SizedBox(height: 18),

          // ─── Sensor Fisik ─────────────────────────────────
          _sectionHeader(context, 'Parameter Sensor Fisik',
              Icons.sensors_rounded, Colors.teal),
          const SizedBox(height: 10),
          Obx(() => _sensorGrid(context, ctrl)),
          const SizedBox(height: 18),

          // ─── Warna RGB ────────────────────────────────────
          _sectionHeader(context, 'Sensor Warna RGB — TCS3200',
              Icons.color_lens_rounded, Colors.indigo),
          const SizedBox(height: 10),
          Obx(() => _rgbCard(context, ctrl)),
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
            Colors.purple.withOpacity(0.12),
            Colors.deepPurple.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.purple, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Validasi Kualitas Minyak', style: AppText.h2(context)),
                const SizedBox(height: 4),
                const Text(
                  'Pembacaan turbiditas, viskositas, dan warna RGB untuk menentukan '
                  'kelayakan minyak goreng hasil purifikasi.',
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
  // FUZZY SCORE CARD
  // ─────────────────────────────────────────────────────────────
  Widget _fuzzyScoreCard(BuildContext context, DashboardController ctrl) {
    final score = ctrl.kelayakan.value;
    final status = ctrl.statusLayak.value;
    final hasData = score > 0;

    Color color;
    IconData icon;

    if (!hasData) {
      color = Colors.grey;
      icon = Icons.hourglass_empty_rounded;
    } else if (score > 85) {
      color = Colors.teal;
      icon = Icons.check_circle_rounded;
    } else if (score > 55) {
      color = Colors.orange;
      icon = Icons.info_rounded;
    } else {
      color = Colors.red;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasData ? status : 'Menunggu Data Fuzzy...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasData
                          ? 'Hasil inferensi fuzzy logic dari ESP32 Master'
                          : 'Sensor belum mengirim data atau sistem belum aktif',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Score Badge
              if (hasData)
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.4), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text('/100', style: TextStyle(fontSize: 9, color: color)),
                    ],
                  ),
                ),
            ],
          ),
          if (hasData) ...[
            const SizedBox(height: 14),
            // Progress bar
            Row(
              children: [
                const Text('Skor Kelayakan:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${score.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            const SizedBox(height: 10),
            // Skala referensi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _scaleBadge('0–41', 'Tidak Layak', Colors.red),
                _scaleBadge('42–75', 'Kurang Layak', Colors.orange),
                _scaleBadge('76–90', 'Layak', Colors.lightGreen),
                _scaleBadge('91–100', 'Sangat Layak', Colors.teal),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scaleBadge(String range, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 3),
        Text(range,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SENSOR GRID (Volume, NTU, Viskositas)
  // ─────────────────────────────────────────────────────────────
  Widget _sensorGrid(BuildContext context, DashboardController ctrl) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _sensorTile(
                context,
                label: 'Volume Minyak\nTangki Validasi',
                value: ctrl.validasiVol.value.toStringAsFixed(1),
                unit: 'L',
                icon: Icons.water_drop_rounded,
                color: Colors.blue,
                hint: 'HC-SR04 Ultrasonik',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sensorTile(
                context,
                label: 'Turbiditas\n(Kekeruhan)',
                value: ctrl.ntu.value.toStringAsFixed(1),
                unit: 'NTU',
                icon: Icons.blur_on_rounded,
                color: Colors.teal,
                hint: 'ADS1115 + Sensor Optik',
                warningThreshold: 50.0,
                currentValue: ctrl.ntu.value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Viskositas full width
        _sensorTileWide(
          context,
          label: 'Viskositas Minyak',
          value: ctrl.viscosity.value.toStringAsFixed(0),
          unit: 'cP',
          icon: Icons.speed_rounded,
          color: Colors.indigo,
          hint: 'Diukur dari frekuensi sensor 555 Timer',
          subtitle: _viscosityStatus(ctrl.viscosity.value),
        ),
      ],
    );
  }

  Widget _sensorTile(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? hint,
    double? warningThreshold,
    double? currentValue,
  }) {
    final bool isWarning = warningThreshold != null &&
        currentValue != null &&
        currentValue >= warningThreshold;
    final tileColor = isWarning ? Colors.red : color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tileColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tileColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tileColor, size: 18),
              const SizedBox(width: 6),
              if (hint != null)
                Expanded(
                  child: Text(hint,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tileColor,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 12, color: tileColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey, height: 1.3)),
          if (isWarning) ...[
            const SizedBox(height: 5),
            const Text('Jernih NTU',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  Widget _sensorTileWide(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? hint,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (hint != null)
                  Text(hint,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ],
                ),
              ),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _viscosityStatus(double v) {
    if (v <= 0) return 'Menunggu data...';
    if (v < 34000) return 'Sangat Kental';
    if (v < 36000) return 'Kental';
    if (v < 36500) return 'Sedang';
    return 'Encer';
  }

  // ─────────────────────────────────────────────────────────────
  // RGB COLOR CARD
  // ─────────────────────────────────────────────────────────────
  Widget _rgbCard(BuildContext context, DashboardController ctrl) {
    final rVal = ctrl.r.value;
    final gVal = ctrl.g.value;
    final bVal = ctrl.b.value;
    final hasColor = rVal > 0 || gVal > 0 || bVal > 0;

    // Preview warna minyak aktual dari TCS3200
    final oilColor =
        hasColor ? Color.fromARGB(255, rVal, gVal, bVal) : Colors.grey[200]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label & Preview Warna
          Row(
            children: [
              // Preview warna minyak
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: oilColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: oilColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Warna Minyak Terdeteksi',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      hasColor
                          ? ctrl.warnaLabel.value
                          : 'Menunggu pembacaan sensor...',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasColor ? Colors.teal : Colors.grey,
                        fontWeight:
                            hasColor ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Sensor: TCS3200 RGB Color Sensor',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Bar RGB masing-masing
          _rgbBar('R — Merah', rVal, Colors.red),
          const SizedBox(height: 8),
          _rgbBar('G — Hijau', gVal, Colors.green),
          const SizedBox(height: 8),
          _rgbBar('B — Biru', bVal, Colors.blue),
        ],
      ),
    );
  }

  Widget _rgbBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 255,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
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
