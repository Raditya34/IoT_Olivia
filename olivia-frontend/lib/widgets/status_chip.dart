import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum StatusKind { success, warning, danger, idle, info }

class StatusChip extends StatelessWidget {
  final String text;
  final StatusKind kind;

  const StatusChip({
    super.key,
    required this.text,
    this.kind = StatusKind.info,
  });

  Color _bg() {
    switch (kind) {
      case StatusKind.success:
        return AppColors.success.withOpacity(0.16);
      case StatusKind.warning:
        return AppColors.orange.withOpacity(0.18);
      case StatusKind.danger:
        return AppColors.danger.withOpacity(0.16);
      case StatusKind.idle:
        return AppColors.textMuted.withOpacity(0.12);
      case StatusKind.info:
        return AppColors.teal.withOpacity(0.14);
    }
  }

  Color _fg() {
    switch (kind) {
      case StatusKind.success:
        return AppColors.success;
      case StatusKind.warning:
        return const Color(0xFF8A6A00);
      case StatusKind.danger:
        return AppColors.danger;
      case StatusKind.idle:
        return const Color(0xFF4B5563);
      case StatusKind.info:
        return AppColors.tealDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _fg().withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: AppText.chip(context).copyWith(color: _fg()),
      ),
    );
  }
}
