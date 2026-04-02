import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/history_record.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  void safeNav(BuildContext context, String route, {Object? args}) {
    // Tutup drawer kalau sedang kebuka (kalau gak kebuka, gak masalah)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Push di frame berikutnya supaya gak nabrak _debugLocked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(route, arguments: args);
    });
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      HistoryRecord(
        id: 'H001',
        stage: 'Arang',
        status: 'Selesai',
        time: DateTime(2026, 1, 26, 10, 32),
        metrics: const {
          'Suhu (°C)': '66.2',
          'Volume (L)': '8.4',
          'Catatan': 'Pemanasan stabil',
        },
        charts: const {
          'Suhu (°C)': [55, 58, 61, 63, 62, 64, 66, 65, 67],
          'Volume (L)': [9.2, 9.0, 8.9, 8.8, 8.7, 8.6, 8.5, 8.5, 8.4],
        },
        icon: Icons.local_fire_department_rounded,
        color: AppColors.success,
      ),
      HistoryRecord(
        id: 'H002',
        stage: 'Bleaching',
        status: 'Normal',
        time: DateTime(2026, 1, 26, 10, 40),
        metrics: const {
          'Suhu (°C)': '74.1',
          'Durasi': '18 menit',
          'Heater': 'ON',
        },
        charts: const {
          'Suhu (°C)': [68, 70, 72, 73, 74, 74, 75, 74, 76],
        },
        icon: Icons.science_rounded,
        color: AppColors.warning,
      ),
      HistoryRecord(
        id: 'H003',
        stage: 'Validasi',
        status: 'Layak',
        time: DateTime(2026, 1, 26, 11, 10),
        metrics: const {
          'Volume (L)': '7.9',
          'Turbidity (NTU)': '38',
          'Viskositas (cP)': '52',
          'Warna': 'Jernih',
        },
        charts: const {
          'Turbidity (NTU)': [120, 98, 80, 62, 49, 41, 39, 35, 32],
          'Viskositas (cP)': [70, 66, 62, 60, 58, 55, 54, 53, 52],
        },
        icon: Icons.verified_rounded,
        color: AppColors.success,
      ),
    ];

    return AppScaffold(
      title: 'History',
      currentRoute: AppRoutes.history,
      onNavigate: (r) => _navigate(context, r),
      child: ListView(
        children: [
          Text('Riwayat Proses', style: AppText.h2(context)),
          const SizedBox(height: 6),
          Text('Klik item untuk melihat detail sensor & trend.',
              style: AppText.muted(context)),
          const SizedBox(height: 12),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _card(context, e),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, HistoryRecord e) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(
            context,
            AppRoutes.historyDetail,
            arguments: e, // HistoryRecord
          );
        });
      },
      child: Container(
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: e.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(e.icon, color: e.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.stage, style: AppText.h3(context)),
                  const SizedBox(height: 4),
                  Text(
                    e.time
                        .toIso8601String()
                        .replaceFirst("T", " ")
                        .substring(0, 16),
                    style: AppText.caption(context),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: e.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: e.color.withOpacity(0.25)),
              ),
              child: Text(
                e.status.toUpperCase(),
                style: AppText.chip(context).copyWith(color: e.color),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
