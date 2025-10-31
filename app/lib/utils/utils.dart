import 'dart:ui';

import 'package:rimado/configs/configs.dart';
import 'package:rimado/models/floor_plan.dart';

class Utils {
  // 値を最も近い増分にスナップさせるヘルパー関数
  double snapToGrid(double value, double snapIncrement) {
    return (value / snapIncrement).round() * snapIncrement;
  }
}
