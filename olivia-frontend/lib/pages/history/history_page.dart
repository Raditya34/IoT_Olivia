import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Tambahkan GetX

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/history_record.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data Dummy (Bisa diganti dari API Laravel nanti)
    final items = [
      HistoryRecord(
        id: 'H001',
        stage: 'Arang',
        status: 'Selesai',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        metrics: const {
          'Suhu (°C)': '66.2',
          'Volume (L)': '12.0',
        },
        charts: const {
          'Suhu': [60, 62, 65, 66.2]
        },
        icon: Icons.local_fire_department_rounded,
        color: Colors.orange,
      ),
      HistoryRecord(
        id: 'H002',
        stage: 'Bleaching',
        status: 'Proses',
        time: DateTime.now().subtract(const Duration(minutes: 30)),
        metrics: const {
          'Suhu (°C)': '75.0',
          'Volume (L)': '11.8',
        },
        charts: const {
          'Suhu': [70, 72, 74, 75.0]
        },
        icon: Icons.science_rounded,
        color: Colors.blue,
      ),
    ];

    return AppScaffold(
      title: 'Riwayat Proses',
      currentRoute: AppRoutes.history,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final e = items[index];
          return InkWell(
            onTap: () {
              // GetX: Pindah halaman dan bawa data 'e'
              Get.toNamed(
                AppRoutes.historyDetail,
                arguments: e,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
