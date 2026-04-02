import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'mini_sparkline.dart';

class SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  // ✅ optional mini chart
  final List<double>? spark;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    required this.icon,
    this.spark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.tealDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.caption(context)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(value, style: AppText.h2(context)),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(unit, style: AppText.muted(context)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (spark != null && spark!.length >= 2) ...[
            const SizedBox(height: 12),
            MiniSparkline(data: spark!, height: 58),
          ],
        ],
      ),
    );
  }
}
