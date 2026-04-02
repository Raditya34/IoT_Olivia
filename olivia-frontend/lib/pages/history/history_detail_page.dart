import 'package:flutter/material.dart';

import '../../models/history_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mini_sparkline.dart';
import '../../routes/app_routes.dart';

class HistoryDetailPage extends StatelessWidget {
  final HistoryRecord record;

  const HistoryDetailPage({super.key, required this.record});

  void _navigate(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detail Riwayat',
      currentRoute: AppRoutes.historyDetail,
      onNavigate: (r) => _navigate(context, r),
      child: ListView(
        children: [
          _header(context),
          const SizedBox(height: 12),
          Text('Snapshot', style: AppText.h2(context)),
          const SizedBox(height: 8),
          _metrics(context),
          const SizedBox(height: 16),
          Text('Trend (dummy)', style: AppText.h2(context)),
          const SizedBox(height: 8),
          ...record.charts.entries
              .map((e) => _chartCard(context, e.key, e.value)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
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
              color: record.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: record.color.withOpacity(0.25)),
            ),
            child: Icon(record.icon, color: record.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.stage, style: AppText.h2(context)),
                const SizedBox(height: 4),
                Text(
                  '${record.time.toIso8601String().replaceFirst("T", " ").substring(0, 16)}',
                  style: AppText.caption(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: record.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: record.color.withOpacity(0.25)),
            ),
            child: Text(
              record.status.toUpperCase(),
              style: AppText.chip(context).copyWith(color: record.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics(BuildContext context) {
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

  Widget _chartCard(BuildContext context, String title, List<double> data) {
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
          const SizedBox(height: 10),
          MiniSparkline(data: data, height: 88, strokeWidth: 2.4),
        ],
      ),
    );
  }
}
