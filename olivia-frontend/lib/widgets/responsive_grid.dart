import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final double minItemWidth;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.gap = 14,
    this.minItemWidth = 260,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final cols = (w / minItemWidth).floor().clamp(1, 4);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((child) {
            final itemW = (w - (gap * (cols - 1))) / cols;
            return SizedBox(width: itemW, child: child);
          }).toList(),
        );
      },
    );
  }
}
