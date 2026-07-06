import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class ProgressTimeline extends StatelessWidget {
  /// 0 = idle/standby
  /// 1 = Arang      (START → HEATER1 → VALVE → PUMP1)
  /// 2 = Bleaching  (HEATER2 → MOTOR → FILTER_BLEACHING → PUMP2)
  /// 3 = Validasi   (DELAY_PUMP3 → PUMP3_RUN)
  /// 4 = Selesai    (setelah PUMP3 selesai)
  final int step;
  final bool active;

  const ProgressTimeline({
    super.key,
    required this.step,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Arang', Icons.local_fire_department_rounded),
      ('Bleaching', Icons.science_rounded),
      ('Validasi', Icons.biotech_rounded),
      ('Selesai', Icons.verified_rounded),
    ];

    // Badge kanan atas
    final String badgeLabel = step >= 4
        ? 'SELESAI'
        : !active || step == 0
            ? 'IDLE'
            : 'RUNNING';

    final bool isRunning = step >= 4 || (active && step > 0);

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
              Text('Progress', style: AppText.h3(context)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isRunning ? AppColors.teal : AppColors.textMuted)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (isRunning ? AppColors.teal : AppColors.textMuted)
                        .withOpacity(0.25),
                  ),
                ),
                child: Text(
                  badgeLabel,
                  style: AppText.chip(context).copyWith(
                    color: isRunning ? AppColors.tealDark : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final nodeW = (w - 24) / 4; // 3 gap × 8px = 24
              return Row(
                children: List.generate(items.length, (i) {
                  final firmStep = i + 1; // 1..4
                  // done  = fase ini sudah LEWAT (tidak digerbang oleh `active`,
                  // karena firmware sempat set system_on=false tepat saat step
                  // mencapai 4/Selesai — kalau digerbang, "Selesai" tidak pernah nyala)
                  final bool done = step > firmStep;
                  // current = firmware SEDANG di fase ini
                  final bool current =
                      step == firmStep && (active || step == 4);

                  final Color color = done
                      ? AppColors.success
                      : current
                          ? AppColors.warning
                          : AppColors.textMuted;

                  return Row(
                    children: [
                      SizedBox(
                        width: nodeW,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: done
                                    ? AppColors.success.withOpacity(0.14)
                                    : current
                                        ? AppColors.warning.withOpacity(0.14)
                                        : AppColors.textMuted.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withOpacity(0.35),
                                ),
                              ),
                              child: Icon(items[i].$2, color: color),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              items[i].$1,
                              style: AppText.caption(context).copyWith(
                                color: done || current
                                    ? AppColors.textDark
                                    : AppColors.textMuted,
                                fontWeight: done || current
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != items.length - 1)
                        Container(
                          width: 8,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 22),
                          // connector ikut teal saat step sudah MELEWATI fase ini
                          color: (step > firmStep)
                              ? AppColors.success.withOpacity(0.7)
                              : AppColors.border,
                        ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
