// lib/pages/history/history_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/history_record.dart';

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final cycleNumber = args['cycleNumber'];
    final rawRecords = args['records'] as List;

    // Map json list ke list Object HistoryRecord agar aman dari error parsing tipe data
    final List<HistoryRecord> records = rawRecords
        .map((item) => HistoryRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return AppScaffold(
      title: 'Detail Cycle #$cycleNumber',
      currentRoute: AppRoutes.historyDetail,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _header(context, cycleNumber, records),
          const SizedBox(height: 20),
          Text('Timeline Proses', style: AppText.h2(context)),
          const SizedBox(height: 12),
          _timeline(context, records),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header(
      BuildContext context, String cycleNumber, List<HistoryRecord> records) {
    final allCompleted =
        records.any((r) => r.stage == 'selesai' && r.status == 'completed');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            allCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: allCompleted ? Colors.green : Colors.orange,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siklus Produksi #$cycleNumber',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  allCompleted
                      ? 'Status: Selesai Sepenuhnya'
                      : 'Status: Dalam Tahapan Proses',
                  style: TextStyle(
                    color: allCompleted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context, List<HistoryRecord> records) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isLast = index == records.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sisi Indikator Grafik Bergaris (Timeline Node)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: record.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(record.icon, color: record.color, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Sisi Konten Riwayat / Teks Sensor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStageName(record.stage),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        DateFormat('HH:mm').format(record.time),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Status: ${record.status.toUpperCase()}",
                    style: TextStyle(
                        fontSize: 12,
                        color: record.status == 'completed'
                            ? Colors.green[700]
                            : Colors.blue[700],
                        fontWeight: FontWeight.bold),
                  ),
                  // MENAMPILKAN DATA SENSOR & AKTUATOR DARI LARAVEL DETAILS
                  if (record.details != null && record.details!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.details!,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[700], height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStageName(String stage) {
    switch (stage) {
      case 'arang':
        return 'Proses Arang';
      case 'bleaching':
        return 'Proses Bleaching';
      case 'validasi':
        return 'Proses Validasi';
      case 'selesai':
        return 'Siklus Selesai';
      default:
        return 'Tahapan Tidak Diketahui';
    }
  }
}
