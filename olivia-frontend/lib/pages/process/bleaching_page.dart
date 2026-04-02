import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/status_chip.dart';

class BleachingPage extends StatefulWidget {
  const BleachingPage({super.key});

  @override
  State<BleachingPage> createState() => _BleachingPageState();
}

class _BleachingPageState extends State<BleachingPage> {
  static const int _window = 24;

  double suhu = 74.2;
  final List<double> _sparkSuhu =
      List<double>.from([68, 70, 72, 73, 74, 74, 75]);

  Timer? _timer;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        suhu = (suhu + _rnd.nextDouble() * 1.0 - 0.5).clamp(40, 95);
        _push(_sparkSuhu, suhu);
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
      title: 'Proses Bleaching',
      currentRoute: AppRoutes.bleaching,
      onNavigate: (r) => _navigate(context, r),
      child: ListView(
        children: [
          _hero(context),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Sensor Monitoring', 'Grafik Bleaching.'),
          const SizedBox(height: 10),
          SensorCard(
            label: 'Suhu Bleaching',
            value: suhu.toStringAsFixed(1),
            unit: '°C',
            icon: Icons.thermostat_auto_rounded,
            spark: _sparkSuhu,
          ),
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
            child: const Icon(Icons.science_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahap Bleaching', style: AppText.h2(context)),
                const SizedBox(height: 4),
                Text('Kontrol suhu untuk proses bleaching.',
                    style: AppText.muted(context)),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatusChip(
                        text: 'Status: Monitoring', kind: StatusKind.info),
                    StatusChip(text: 'Heater: ON', kind: StatusKind.warning),
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
}
