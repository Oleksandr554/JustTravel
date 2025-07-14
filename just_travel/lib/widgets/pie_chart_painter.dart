import 'package:flutter/material.dart';
import 'dart:math';

class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  PieChartPainter({required this.data});

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Ongoing': return const Color(0xFFE53935); 
      case 'Draft': return const Color(0xFF7CB342);   
      case 'Past': return const Color(0xFF1E88E5);    
      case 'Upcoming': return const Color(0xFFFFB300); 
      default: return Colors.grey;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (sum, item) => sum + item);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.80; 
    final strokeWidth = radius * 0.1; 
    final innerRadius = radius - strokeWidth;

    double startAngle = -pi / 2; 

    data.forEach((status, value) {
      if (value > 0) { 
        final sweepAngle = (value / total) * 2 * pi;
        final paint = Paint()
            ..color = _getColorForStatus(status)
            ..style = PaintingStyle.stroke 
            ..strokeWidth = strokeWidth;

        canvas.drawArc(
            Rect.fromCircle(center: center, radius: innerRadius + strokeWidth / 2), 
            startAngle,
            sweepAngle - 0.03, 
            false, 
            paint,
        );
        startAngle += sweepAngle;
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      if (oldDelegate.data.length != data.length) return true;
      for (var key in data.keys) {
        if (oldDelegate.data[key] != data[key]) return true;
      }
      return false;
    }
    return true;
  }
}