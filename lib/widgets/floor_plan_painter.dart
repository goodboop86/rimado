import 'package:flutter/material.dart';
import '../models/floor_plan.dart';

class FloorPlanPainter extends CustomPainter {
  final FloorPlan floorPlan;

  FloorPlanPainter({required this.floorPlan});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var layout in floorPlan.layouts) {
      if (layout.vertices.isEmpty) continue;

      // レイアウトの塗りつぶし
      final fillPaint = Paint()
        ..color = layout.getColor()
        ..style = PaintingStyle.fill;

      // レイアウトの枠線
      final borderPaint = Paint()
        ..color = layout.getBorderColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final path = Path();
      path.moveTo(layout.vertices[0].x, layout.vertices[0].y);
      for (var i = 1; i < layout.vertices.length; i++) {
        path.lineTo(layout.vertices[i].x, layout.vertices[i].y);
      }
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);

      // レイアウト名の描画
      // 頂点から中心座標を計算し、そこにテキストを描画
      double minX = layout.vertices[0].x;
      double maxX = layout.vertices[0].x;
      double minY = layout.vertices[0].y;
      double maxY = layout.vertices[0].y;

      for (var vertex in layout.vertices) {
        if (vertex.x < minX) minX = vertex.x;
        if (vertex.x > maxX) maxX = vertex.x;
        if (vertex.y < minY) minY = vertex.y;
        if (vertex.y > maxY) maxY = vertex.y;
      }

      final centerX = (minX + maxX) / 2;
      final centerY = (minY + maxY) / 2;

      textPainter.text = TextSpan(
        text: layout.name,
        style: TextStyle(
          color: Colors.black,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centerX - textPainter.width / 2,
          centerY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // レイアウトデータが変わらない限り再描画不要
  }
}
