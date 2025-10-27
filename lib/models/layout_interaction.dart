import 'dart:ui';

import 'package:rimado/enums/enums.dart';
import 'package:rimado/models/floor_plan.dart';

class LayoutInteraction {
  String? selectedLayoutId; // 選択中のレイアウトID
  int? selectedVertexIndex; // 選択中の頂点インデックス
  DragMode dragMode = DragMode.none; // ドラッグモード
  Offset? panStartOffset; // ドラッグ開始時のグローバル位置
  List<Vertex>? originalVertices; // ドラッグ開始時の頂点リスト

  // リセット用のメソッドなども追加可能
  void reset() {
    selectedLayoutId = null;
    selectedVertexIndex = null;
    dragMode = DragMode.none;
    panStartOffset = null;
    originalVertices = null;
  }
}
