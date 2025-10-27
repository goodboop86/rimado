import 'dart:ui';

import 'package:rimado/configs/configs.dart';
import 'package:rimado/models/floor_plan.dart';

class Utils {
  // タップされた位置にある頂点を判定するヘルパー関数
  int? findVertexAtTap(Layout layout, Offset tapPosition) {
    const double handleRadius = 10.0;
    for (var i = 0; i < layout.vertices.length; i++) {
      final vertex = layout.vertices[i];
      final distance = (tapPosition - Offset(vertex.x, vertex.y)).distance;
      if (distance <= handleRadius) {
        return i;
      }
    }
    return null;
  }

  // タップされた位置がどのレイアウト内にあるかを判定するヘルパー関数
  String? findLayoutAtTap(Offset tapPosition, FloorPlan floorPlan) {
    for (var layout in floorPlan.layouts) {
      final path = Path();
      if (layout.vertices.isNotEmpty) {
        path.moveTo(layout.vertices[0].x, layout.vertices[0].y);
        for (var i = 1; i < layout.vertices.length; i++) {
          path.lineTo(layout.vertices[i].x, layout.vertices[i].y);
        }
        path.close();
        if (path.contains(tapPosition)) {
          return layout.id;
        }
      }
    }
    return null;
  }

  // 値を最も近い増分にスナップさせるヘルパー関数
  double snapToGrid(double value, double snapIncrement) {
    return (value / snapIncrement).round() * snapIncrement;
  }
}
