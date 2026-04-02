import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GradientBackground({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background),
      child: SafeArea(
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
