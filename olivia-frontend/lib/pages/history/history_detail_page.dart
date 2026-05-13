// lib/pages/history/history_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari arguments
    final args = Get.arguments as Map<String, dynamic>;
    final cycleNumber = args['cycleNumber'];
    final records = args['records'] as List;

    return AppScaffold(
      title: 'Detail Cycle #$cycleNumber',
      currentRoute: AppRoutes.historyDetail,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _header(context, cycleNumber, records),
          const SizedBox(height: 16),
          Text('Timeline Proses', style: AppText.h2(context)),
          const SizedBox(height: 12),
          _timeline(context, records),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String cycleNumber, List records) {
    final allCompleted = records.every((r) => r['status'] == 'completed');
    final statusColor = allCompleted ? Colors.green : Colors.orange;
    final statusText = allCompleted ? 'SELESAI' : 'BERLANGSUNG';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.teal.withOpacity(0.1), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.timeline_rounded,
                color: AppColors.teal, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cycle #$cycleNumber', style: AppText.h1(context)),
                Text('${records.length} tahapan',
                    style: AppText.muted(context)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context, List records) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(records.length, (index) {
          final record = records[index];
          return _timelineItem(context, record,
              isLast: index == records.length - 1);
        }),
      ),
    );
  }

  Widget _timelineItem(BuildContext context, Map<String, dynamic> record,
      {required bool isLast}) {
    final stage = record['stage'];
    final status = record['status'];
    final startedAt = record['started_at'];
    final completedAt = record['completed_at'];

    final stageData = _getStageData(stage);
    final isCompleted = status == 'completed';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line & dot
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? stageData['color'] as Color
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                stageData['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted
                    ? stageData['color'] as Color
                    : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getStageName(stage),
                        style: AppText.h3(context),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (stageData['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 16, color: stageData['color'] as Color),
                            const SizedBox(width: 4),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: stageData['color'] as Color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isCompleted && startedAt != null)
                  _infoRow(context, Icons.play_arrow_rounded,
                      'Mulai: ${_formatDateTime(startedAt)}'),
                if (isCompleted && completedAt != null)
                  _infoRow(context, Icons.check_circle_outline_rounded,
                      'Selesai: ${_formatDateTime(completedAt)}'),
                if (!isCompleted)
                  _infoRow(context, Icons.pending_outlined, 'Menunggu...',
                      isGray: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text,
      {bool isGray = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isGray ? Colors.grey : AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isGray ? Colors.grey : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStageData(String stage) {
    switch (stage) {
      case 'arang':
        return {
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.orange,
        };
      case 'bleaching':
        return {
          'icon': Icons.science_rounded,
          'color': Colors.blue,
        };
      case 'validasi':
        return {
          'icon': Icons.verified_rounded,
          'color': Colors.purple,
        };
      case 'selesai':
        return {
          'icon': Icons.check_circle_rounded,
          'color': Colors.green,
        };
      default:
        return {
          'icon': Icons.circle_outlined,
          'color': Colors.grey,
        };
    }
  }

  String _getStageName(String stage) {
    switch (stage) {
      case 'arang':
        return 'Proses Arang';
      case 'bleaching':
        return 'Bleaching';
      case 'validasi':
        return 'Validasi';
      case 'selesai':
        return 'Selesai';
      default:
        return stage;
    }
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('dd MMM HH:mm:ss').format(date);
    } catch (e) {
      return timestamp;
    }
  }
}
