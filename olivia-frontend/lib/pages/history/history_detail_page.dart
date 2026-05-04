import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Tambahkan GetX

import '../../models/history_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
// Jika Anda punya widget ini, aktifkan kembali importnya:
// import '../../widgets/mini_sparkline.dart';
import '../../routes/app_routes.dart';

class HistoryDetailPage extends StatelessWidget {
  // Tidak perlu lagi mendefinisikan 'final HistoryRecord record' di sini
  // karena datanya diambil langsung dari Get.arguments
  const HistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data yang dikirim dari history_page.dart
    final HistoryRecord record = Get.arguments;

    return AppScaffold(
      title: 'Detail Riwayat',
      currentRoute: AppRoutes.historyDetail,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _header(context, record),
          const SizedBox(height: 12),
          Text('Snapshot', style: AppText.h2(context)),
          const SizedBox(height: 8),
          _metrics(context, record),
          const SizedBox(height: 16),
          Text('Trend (dummy)', style: AppText.h2(context)),
          const SizedBox(height: 8),
          ...record.charts.entries
              .map((e) => _chartCard(context, e.key, e.value, record)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, HistoryRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: record.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: record.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(record.icon, size: 42, color: record.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.stage, style: AppText.h1(context)),
                Text(
                  record.time
                      .toIso8601String()
                      .replaceFirst("T", " ")
                      .substring(0, 16),
                  style: AppText.muted(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: record.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.status.toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics(BuildContext context, HistoryRecord record) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: record.metrics.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(e.key, style: AppText.muted(context))),
                Text(e.value, style: AppText.body(context)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartCard(BuildContext context, String title, List<double> data,
      HistoryRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3(context)),
          const SizedBox(height: 12),
          // Tempatkan Widget MiniSparkline Anda di sini (jika ada)
          // Contoh fallback jika belum menggunakan MiniSparkline:
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: record.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'Data Grafik: ${data.join(', ')}',
                style: AppText.muted(context),
              ),
            ),
          )
        ],
      ),
    );
  }
}
