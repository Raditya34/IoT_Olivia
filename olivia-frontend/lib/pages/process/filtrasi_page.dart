import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/status_chip.dart';

class ValidasiPage extends StatefulWidget {
  const ValidasiPage({super.key});

  @override
  State<ValidasiPage> createState() => _ValidasiPageState();
}

class _ValidasiPageState extends State<ValidasiPage> {
  static const int _window = 24;

  double volume = 7.9;
  double turbidity = 38.0;
  double viskositas = 52.0;
  String warna = 'Jernih';

  // ✅ spark buffers
  final List<double> _sparkVol =
      List<double>.from([9.0, 8.8, 8.6, 8.4, 8.2, 8.0, 7.9]);
  final List<double> _sparkTurb =
      List<double>.from([120, 98, 80, 62, 49, 41, 38]);
  final List<double> _sparkVisc =
      List<double>.from([70, 66, 62, 60, 58, 55, 52]);

  Timer? _timer;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        volume = (volume + _rnd.nextDouble() * 0.2 - 0.1).clamp(0, 15);
        turbidity = (turbidity + _rnd.nextDouble() * 6 - 3).clamp(0, 200);
        viskositas = (viskositas + _rnd.nextDouble() * 3 - 1.5).clamp(10, 120);

        _push(_sparkVol, volume);
        _push(_sparkTurb, turbidity);
        _push(_sparkVisc, viskositas);

        if (turbidity < 40) {
          warna = 'Jernih';
        } else if (turbidity < 90) {
          warna = 'Kurang Jernih';
        } else {
          warna = 'Kotor';
        }
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

  String _hasil() {
    if (warna == 'Jernih' && turbidity < 50 && viskositas < 70) return 'Layak';
    if (warna != 'Kotor' && turbidity < 90) return 'Perlu Cek';
    return 'Tidak Layak';
  }

  Color _hasilColor() {
    final h = _hasil();
    if (h == 'Layak') return AppColors.success;
    if (h == 'Perlu Cek') return AppColors.warning;
    return AppColors.danger;
  }

  static StatusKind _toKind(String hasil) {
    if (hasil == 'Layak') return StatusKind.success;
    if (hasil == 'Perlu Cek') return StatusKind.warning;
    return StatusKind.danger;
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil();
    final hColor = _hasilColor();

    return AppScaffold(
      title: 'Proses Validasi',
      currentRoute: AppRoutes.filtrasi,
      onNavigate: (r) => _navigate(context, r),
      child: ListView(
        children: [
          _hero(context, hasil, hColor),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Sensor Validasi', 'Grafik Validasi.'),
          const SizedBox(height: 10),
          _sensorGrid(context),
          const SizedBox(height: 16),
          _resultCard(context, hasil, hColor),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, String hasil, Color hColor) {
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
            child: const Icon(Icons.verified_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahap Validasi', style: AppText.h2(context)),
                const SizedBox(height: 4),
                Text('Penilaian kualitas minyak berdasarkan sensor.',
                    style: AppText.muted(context)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    const StatusChip(
                        text: 'Status: Monitoring', kind: StatusKind.info),
                    StatusChip(text: 'Hasil: $hasil', kind: _toKind(hasil)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: hColor.withOpacity(0.25)),
            ),
            child: Text(
              hasil.toUpperCase(),
              style: AppText.chip(context).copyWith(color: hColor),
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
        final cols = w < 520 ? 1 : (w < 980 ? 2 : 4);
        final cardW = (w - (12 * (cols - 1))) / cols;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
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
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Turbidity',
                value: turbidity.toStringAsFixed(0),
                unit: 'NTU',
                icon: Icons.blur_on_rounded,
                spark: _sparkTurb,
              ),
            ),
            SizedBox(
              width: cardW,
              child: SensorCard(
                label: 'Viskositas',
                value: viskositas.toStringAsFixed(0),
                unit: 'cP',
                icon: Icons.speed_rounded,
                spark: _sparkVisc,
              ),
            ),
            SizedBox(width: cardW, child: _warnaCard(context)),
          ],
        );
      },
    );
  }

  Widget _warnaCard(BuildContext context) {
    Color c;
    if (warna == 'Jernih') {
      c = AppColors.success;
    } else if (warna == 'Kurang Jernih') {
      c = AppColors.warning;
    } else {
      c = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(14),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.opacity_rounded, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Warna', style: AppText.caption(context)),
                const SizedBox(height: 6),
                Text(warna, style: AppText.h2(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, String hasil, Color hColor) {
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
              color: hColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.analytics_rounded, color: hColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rekomendasi: ${hasil == 'Layak' ? 'Siap digunakan / disimpan.' : hasil == 'Perlu Cek' ? 'Pertimbangkan pemurnian tambahan.' : 'Disarankan ulang proses filtrasi.'}',
              style: AppText.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
