import 'package:flutter/material.dart';

class HistoryRecord {
  final String id;
  final String stage; // arang, bleaching, validasi, selesai
  final String status; // started, completed
  final DateTime time;
  final String? details;
  final int cycleNumber;
  final IconData icon;
  final Color color;

  const HistoryRecord({
    required this.id,
    required this.stage,
    required this.status,
    required this.time,
    this.details,
    required this.cycleNumber,
    required this.icon,
    required this.color,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    String stageStr = json['stage'] ?? '';
    IconData iconData;
    Color colorData;

    switch (stageStr) {
      case 'arang':
        iconData = Icons.local_fire_department_rounded;
        colorData = Colors.orange;
        break;
      case 'bleaching':
        iconData = Icons.science_rounded;
        colorData = Colors.blue;
        break;
      case 'validasi':
        iconData = Icons.verified_rounded;
        colorData = Colors.purple;
        break;
      case 'selesai':
        iconData = Icons.check_circle_rounded;
        colorData = Colors.green;
        break;
      default:
        iconData = Icons.circle_outlined;
        colorData = Colors.grey;
    }

    return HistoryRecord(
      id: json['id']?.toString() ?? '',
      stage: stageStr,
      status: json['status'] ?? '',
      // FIX: Menggunakan created_at sesuai respon database postgresql backend
      time: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      details: json['details']?.toString(),
      cycleNumber: int.tryParse(json['cycle_number'].toString()) ?? 1,
      icon: iconData,
      color: colorData,
    );
  }
}
