import 'package:ai_calc_app/stroke.dart';
import 'package:flutter/material.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke currentStroke;
  final double strokeWidth;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (Stroke stroke in strokes) {
      Paint paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    Paint currentPaint = Paint()
      ..color = currentStroke.color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    for (int i = 0; i < currentStroke.points.length - 1; i++) {
      if (currentStroke.points[i] != null && currentStroke.points[i + 1] != null) {
        canvas.drawLine(currentStroke.points[i]!, currentStroke.points[i + 1]!, currentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return true;
  }
}