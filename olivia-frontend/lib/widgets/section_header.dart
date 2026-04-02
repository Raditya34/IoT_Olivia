import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h2(context)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppText.muted(context)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          IconTheme(
            data: const IconThemeData(color: AppColors.textMuted),
            child: trailing!,
          )
        ],
      ],
    );
  }
}
