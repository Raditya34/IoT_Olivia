import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum IndustrialNoticeKind { info, warning, success }

class IndustrialPopup {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IndustrialNoticeKind kind = IndustrialNoticeKind.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    hide();

    final colors = _kindColors(kind);
    final overlay = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 18,
        left: 18,
        right: 18,
        child: SafeArea(
          child: _PopupCard(
            title: title,
            message: message,
            accent: colors.$1,
            icon: colors.$2,
            onClose: hide,
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    Future.delayed(duration, () => hide());
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  static (Color, IconData) _kindColors(IndustrialNoticeKind kind) {
    switch (kind) {
      case IndustrialNoticeKind.success:
        return (AppColors.success, Icons.check_circle_rounded);
      case IndustrialNoticeKind.warning:
        return (AppColors.warning, Icons.warning_rounded);
      case IndustrialNoticeKind.info:
        return (AppColors.tealDark, Icons.info_rounded);
    }
  }
}

class _PopupCard extends StatelessWidget {
  final String title;
  final String message;
  final Color accent;
  final IconData icon;
  final VoidCallback onClose;

  const _PopupCard({
    required this.title,
    required this.message,
    required this.accent,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, (1 - t) * -10),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(0.12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3(context)),
                    const SizedBox(height: 4),
                    Text(message, style: AppText.muted(context)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
