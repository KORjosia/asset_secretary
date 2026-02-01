// 위치: lib/widgets/radar_chart.dart
import 'dart:math';
import 'package:flutter/material.dart';

class RadarChart extends StatelessWidget {
  final List<double> values; // 0~1, length=5
  final List<String> labels; // length=5

  const RadarChart({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: CustomPaint(
        painter: _RadarPainter(values: values, labels: labels),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.34;

    final paintGrid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade300;

    final paintAxis = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade300;

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue.withOpacity(0.18);

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blue.withOpacity(0.65);

    // 5각형 기준 각도
    const n = 5;
    double ang(int i) => (-pi / 2) + (2 * pi * i / n);

    // grid (3단)
    for (int level = 1; level <= 3; level++) {
      final r = radius * (level / 3);
      final path = Path();
      for (int i = 0; i < n; i++) {
        final p = center + Offset(cos(ang(i)), sin(ang(i))) * r;
        if (i == 0) path.moveTo(p.dx, p.dy);
        else path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paintGrid);
    }

    // axis
    for (int i = 0; i < n; i++) {
      final p = center + Offset(cos(ang(i)), sin(ang(i))) * radius;
      canvas.drawLine(center, p, paintAxis);
    }

    // values polygon
    final vPath = Path();
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final p = center + Offset(cos(ang(i)), sin(ang(i))) * (radius * v);
      if (i == 0) vPath.moveTo(p.dx, p.dy);
      else vPath.lineTo(p.dx, p.dy);
    }
    vPath.close();
    canvas.drawPath(vPath, paintFill);
    canvas.drawPath(vPath, paintStroke);

    // labels
    final textStyle = TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w700);
    for (int i = 0; i < n; i++) {
      final p = center + Offset(cos(ang(i)), sin(ang(i))) * (radius + 22);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(p.dx - tp.width / 2, p.dy - tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
