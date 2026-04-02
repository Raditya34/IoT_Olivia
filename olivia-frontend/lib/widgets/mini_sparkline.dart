import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MiniSparkline extends StatelessWidget {
  final List<double> data;
  final double height;
  final double strokeWidth;

  const MiniSparkline({
    super.key,
    required this.data,
    this.height = 56,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: _SparkPainter(
          points: data,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final double strokeWidth;

  _SparkPainter({
    required this.points,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    // Grid ringan
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.7)
      ..strokeWidth = 1;

    for (int i = 1; i <= 2; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line path
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.tealDark;

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final norm = (points[i] - minV) / range; // 0..1
      final y = size.height - (norm * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Dot terakhir
    final lastX = size.width;
    final lastNorm = (points.last - minV) / range;
    final lastY = size.height - (lastNorm * size.height);

    final dotPaint = Paint()..color = AppColors.orangeDeep;
    canvas.drawCircle(Offset(lastX, lastY), 3.4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
