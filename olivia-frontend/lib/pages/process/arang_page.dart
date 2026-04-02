import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/status_chip.dart';

class ArangPage extends StatefulWidget {
  const ArangPage({super.key});

  @override
  State<ArangPage> createState() => _ArangPageState();
}

class _ArangPageState extends State<ArangPage> {
  static const int _window = 24;

  double suhu = 62.4;
  double volume = 8.6;

  // ✅ spark buffers
  final List<double> _sparkSuhu =
      List<double>.from([55, 58, 61, 63, 62, 64, 66]);
  final List<double> _sparkVol =
      List<double>.from([9.2, 9.0, 8.9, 8.8, 8.7, 8.6, 8.5]);

  Timer? _timer;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        suhu = (suhu + _rnd.nextDouble() * 1.2 - 0.6).clamp(40, 95);
        volume = (volume + _rnd.nextDouble() * 0.25 - 0.1).clamp(0, 15);

        _push(_sparkSuhu, suhu);
        _push(_sparkVol, volume);
      });
    });
  }

  void _push(List<double> buf, double v) {
    buf.add(v);
    if (buf.length > _window) buf.removeAt(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Proses Arang',
      currentRoute: AppRoutes.arang,
      onNavigate: (r) => _navigate(context, r),
      child: ListView(
        children: [
          _hero(context),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Sensor Monitoring', 'Grafik Arang Aktif.'),
          const SizedBox(height: 10),
          _sensorGrid(context),
          const SizedBox(height: 16),
          _noteCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.05),
          )
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
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahap Arang', style: AppText.h2(context)),
                const SizedBox(height: 4),
                Text('Kontrol pemanasan & volume minyak.',
                    style: AppText.muted(context)),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatusChip(
                        text: 'Status: Monitoring', kind: StatusKind.info),
                    StatusChip(text: 'Sensor: Aktif', kind: StatusKind.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h2(context)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.muted(context)),
        ],
      ),
    );
  }

  Widget _sensorGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w < 520 ? 1 : 2;
        final cardW = (w - (12 * (cols - 1))) / cols;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Suhu Pemanasan',
                value: suhu.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_rounded,
                spark: _sparkSuhu,
              ),
            ),
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Volume Minyak',
                value: volume.toStringAsFixed(1),
                unit: 'L',
                icon: Icons.water_drop_rounded,
                spark: _sparkVol,
              ),
            ),
          ],
        );
      },
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tips_and_updates_rounded,
                color: AppColors.tealDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sparkline bergerak tiap 2 detik (dummy). Nanti tinggal ganti input dari MQTT.',
              style: AppText.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
