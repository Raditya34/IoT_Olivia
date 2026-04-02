import 'package:flutter/material.dart';

class HistoryRecord {
  final String id;
  final String stage; // Arang/Bleaching/Validasi
  final String status; // Selesai/Layak/dll
  final DateTime time;

  // snapshot dummy (nanti backend)
  final Map<String, String> metrics;
  final Map<String, List<double>> charts;
  final IconData icon;
  final Color color;

  const HistoryRecord({
    required this.id,
    required this.stage,
    required this.status,
    required this.time,
    required this.metrics,
    required this.charts,
    required this.icon,
    required this.color,
  });
}
