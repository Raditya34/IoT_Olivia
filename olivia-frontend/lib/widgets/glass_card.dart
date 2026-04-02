import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blur;
  final BorderRadius borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blur = 12,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.border.withOpacity(0.9)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.06),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent, // <-- PENTING
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
