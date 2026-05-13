// lib/pages/history/history_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/notification_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final notificationService = NotificationService();
  late Future<Map<String, dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = notificationService.getProcessHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = notificationService.getProcessHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Riwayat Proses',
      currentRoute: AppRoutes.history,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Coba Lagi'),
                    )
                  ],
                ),
              );
            }

            final history = snapshot.data ?? {};

            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Belum ada riwayat proses',
                        style: AppText.h3(context)),
                  ],
                ),
              );
            }

            // Sort cycles by number (descending - terbaru di atas)
            final cycles = (history.keys.toList()..sort()).reversed.toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final cycleNumber = cycles[index];
                final records = history[cycleNumber] as List;

                return _cycleCard(context, cycleNumber, records);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _cycleCard(BuildContext context, String cycleNumber, List records) {
    // Ambil stage terakhir untuk status
    final lastStage = records.isNotEmpty ? records.last : null;
    final stage = lastStage?['stage'] ?? 'unknown';
    final status = lastStage?['status'] ?? 'unknown';
    final createdAt = lastStage?['created_at'];

    final stageData = _getStageData(stage);

    return InkWell(
      onTap: () {
        // Pindah ke detail dengan membawa data cycle
        Get.toNamed(
          AppRoutes.historyDetail,
          arguments: {'cycleNumber': cycleNumber, 'records': records},
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
                color: stageData['color'].withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(stageData['icon'], color: stageData['color']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cycle #$cycleNumber', style: AppText.h3(context)),
                  const SizedBox(height: 4),
                  Text(
                    '${_getStageName(stage)} • ${_formatDateTime(createdAt)}',
                    style: AppText.caption(context),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.25)),
              ),
              child: Text(
                _getStatusText(status),
                style: AppText.chip(context)
                    .copyWith(color: _getStatusColor(status)),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
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

  Color _getStatusColor(String status) {
    if (status == 'completed') return Colors.green;
    if (status == 'started') return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText(String status) {
    if (status == 'completed') return 'SELESAI';
    if (status == 'started') return 'PROSES';
    return status.toUpperCase();
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('dd MMM HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }
}
